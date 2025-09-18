module vibe.http.internal.accumulating_stream;
import vibe.core.stream;

auto accumulatingStream(Stream)(Stream stream, ubyte[] buffer) {
    return new AccumulatingStream!Stream(stream, buffer);
}

final class AccumulatingStream(Stream) {
private:
    Stream underlying;
    ubyte[] buf;
    size_t idx;
@safe:
public: 
final:
    this(Stream os, ubyte[] buffer) {
        assert(buffer.length > 0);
        underlying = os;
        idx = 0;
        buf = buffer;
    }

	/** Returns true $(I iff) the end of the input stream has been reached.

		For connection oriented streams, this function will block until either
		new data arrives or the connection got closed.
	*/
	@property bool empty() { return underlying.empty; }

	/**	(Scheduled for deprecation) Returns the maximum number of bytes that are known to remain available for read.

		After `leastSize()` bytes have been read, the stream will either have reached EOS
		and `empty()` returns `true`, or `leastSize()` returns again a number greater than `0`.
	*/
	@property ulong leastSize() { return underlying.leastSize; }

	/** (Scheduled for deprecation) Queries if there is data available for immediate, non-blocking read.
	*/
	@property bool dataAvailableForRead() { return underlying.dataAvailableForRead; }

	/** Returns a temporary reference to the data that is currently buffered.

		The returned slice typically has the size `leastSize()` or `0` if `dataAvailableForRead()`
		returns `false`. Streams that don't have an internal buffer will always return an empty
		slice.

		Note that any method invocation on the same stream potentially invalidates the contents of
		the returned buffer.
	*/
	const(ubyte)[] peek() { return underlying.peek(); }

	/**	Fills the preallocated array 'bytes' with data from the stream.

		This function will continue read from the stream until the buffer has
		been fully filled.

		Params:
			dst = The buffer into which to write the data that was read
			mode = Optional reading mode (defaults to `IOMode.all`).

		Return:
			Returns the number of bytes read. The `dst` buffer will be filled up
			to this index. The return value is guaranteed to be `dst.length` for
			`IOMode.all`.

		Throws: An exception if the operation reads past the end of the stream

		See_Also: `readOnce`, `tryRead`
	*/
	size_t read(scope ubyte[] dst, IOMode mode) { return underlying.read(dst, mode); }
	/// ditto
	final void read(scope ubyte[] dst) { auto n = read(dst, IOMode.all); assert(n == dst.length); }

	size_t write(scope const(ubyte)[] bytes, IOMode mode) @trusted {
        if (idx == 0 && bytes.length >= buf.length) {
            return underlying.write(bytes, mode);
        }
        else if (idx + bytes.length < buf.length) {
            buf[idx .. idx + bytes.length] = bytes[];
            idx += bytes.length;
            return bytes.length;
        } else {
            size_t avail = buf.length - idx;
            buf[idx .. $] = bytes[0..avail];
            idx = buf.length;
            flush();
            return avail + write(bytes[avail..$], mode);
        }
    }
    /// ditto
	final void write(scope const(ubyte)[] bytes) { auto n = write(bytes, IOMode.all); assert(n == bytes.length); }
	/// ditto
	final void write(scope const(char)[] bytes) { write(cast(const(ubyte)[])bytes); }

	void flush() @trusted {
        underlying.write(buf[0..idx]);
        underlying.flush();
        idx = 0;
    }

	/** Flushes and finalizes the stream.

		Finalize has to be called on certain types of streams. No writes are possible after a
		call to finalize().
	*/
	void finalize() {
        flush();
        underlying.finalize();
    }
}