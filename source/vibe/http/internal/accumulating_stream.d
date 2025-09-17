module vibe.http.internal.accumulating_stream;

import vibe.core.stream;

/**
	Interface for all classes implementing writeable streams.
*/
class AccumulatingOutputStream : OutputStream {
private:
    OutputStream underlying;
    ubyte[] buf;
    size_t idx;
@safe:
public: 
    this(OutputStream os, ubyte[] buffer) {
        assert(buffer.length > 0);
        underlying = os;
        idx = 0;
        buf = buffer;
    }

	/** Writes an array of bytes to the stream.
	*/
	override size_t write(scope const(ubyte)[] bytes, IOMode mode) @blocking {
        if (idx + bytes.length < buf.length) {
            buf[idx .. idx + bytes.length] = bytes[];
            idx += bytes.length;
            return bytes.length;
        } else {
            size_t avail = buf.length - idx;
            buf[idx .. $] = bytes[0..avail];
            flush();
            return avail + write(bytes[avail..$], mode);
        }
    }

	/** Flushes the stream and makes sure that all data is being written to the output device.
	*/
	override void flush() {
        underlying.write(buf);
        idx = 0;
    }

	/** Flushes and finalizes the stream.

		Finalize has to be called on certain types of streams. No writes are possible after a
		call to finalize().
	*/
	override void finalize() {
        flush();
        underlying.finalize();
    }
}