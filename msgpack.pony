use "format"
use "assert"
use "itertools"
use "buffered"

type MsgPackable is (None|Bool|Unsigned box|Signed box|Float box|ByteSeq|ReadSeq[MsgPackable] box)

class MsgPacker

    // constants
    let _u127: U8 = U8(127)
    let _minus32: I8 = I8(-32)
    let _null: I8 = I8(0)

    let _writer: Writer = Writer

    fun ref pack(msg: MsgPackable): Array[U8] ? =>
      match msg
      | let n: None box => none()
      | let b: Bool box => bool(b)
      | let u: Unsigned box => unsigned(u)
      | let s: Signed box  => signed(s)
      | let f: Float box   => float(f)
      | let s: String => string(s)
      | let b: ByteSeq => byteseq(b)
      | let a: ReadSeq[MsgPackable] box => array(a)
      else
        error
      end
      let packed = Array[U8].create(_writer.size())
      let byteSeqs: Array[ByteSeq] iso = _writer.done()
      let bs = recover box consume byteSeqs end
      for fragment in bs.values() do
        packed.append(fragment)
      end
      packed

    fun ref none() =>
      _writer.u8(0xc0)

    fun ref bool(b: Bool box) =>
      _writer.u8(if b then 0xc2 else 0xc3 end)

    fun ref unsigned(u: Unsigned box): None ? =>
      match u
      | let u_8: U8 box => u8(u_8)
      | let u_16: U16 box => u16(u_16)
      | let u_32: U32 box => u32(u_32)
      | let u_64: U64 box => u64(u_64)
      | let u_128: U128 box => u128(u_128)
      | let u_size: USize box => u64(u_size.u64())
      | let u_long: ULong box => u64(u_long.u64())
      else
        error
      end

    fun ref signed(i: Signed box): None ? =>
      match i
      | let i_8: I8 box => i8(i_8)
      | let i_16: I16 box => i16(i_16)
      | let i_32: I32 box => i32(i_32)
      | let i_64: I64 box => i64(i_64)
      | let i_128: I128 box => i128(i_128)
      | let i_size: ISize box => i64(i_size.i64())
      | let i_long: ILong box => I64(i_long.i64())
      else
        error
      end

    fun ref float(f: Float box): None ? =>
      match f
      | let f_32: F32 box => f32(f_32)
      | let f_64: F64 box => f64(f_64)
      else
        error
      end

    fun ref u8(u_8: U8 box) =>
      if (u_8 <= _u127) then
        _pos_fixnum(u_8)
      else
        _uint8(u_8)
      end

    fun ref u16(u_16: U16 box) =>
      if (u_16 <= _u127.u16()) then
        _pos_fixnum(u_16)
      elseif u_16 <= U8.max_value().u16() then
        _uint8(u_16)
      else
        _uint16(u_16)
      end

    fun ref u32(u_32: U32 box) =>
      if (u_32 <= _u127.u32()) then
        _pos_fixnum(u_32)
      elseif u_32 <= U8.max_value().u32() then
        _uint8(u_32)
      elseif u_32 <= U16.max_value().u32() then
        _uint16(u_32)
      else
        _uint32(u_32)
      end

    fun ref u64(u_64: U64 box) =>
      if (u_64 <= _u127.u64()) then
        _pos_fixnum(u_64)
      elseif u_64 <= U8.max_value().u64() then
        _uint8(u_64)
      elseif u_64 <= U16.max_value().u64() then
        _uint16(u_64)
      elseif u_64 <= U32.max_value().u64() then
        _uint32(u_64)
      else
        _uint64(u_64)
      end

    fun ref u128(u_128: U128 box): None ? =>
      if (u_128 <= _u127.u128()) then
        _pos_fixnum(u_128)
      elseif u_128 <= U8.max_value().u128() then
        _uint8(u_128)
      elseif u_128 <= U16.max_value().u128() then
        _uint16(u_128)
      elseif u_128 <= U32.max_value().u128() then
        _uint32(u_128)
      elseif u_128 <= U64.max_value().u128() then
        _uint64(u_128)
      else
        error
      end

    fun ref i8(i_8: I8 box) =>
      if (i_8 <= _null) and (i_8 > _minus32) then
        _neg_fixnum(i_8)
      else
        _int8(i_8)
      end


    fun ref i16(i_16: I16 box) =>
      if (i_16 > _null.i16()) and (i_16 > _minus32.i16()) then
        _neg_fixnum(i_16)
      elseif (i_16 <= I8.max_value().i16()) and (i_16 >= I8.min_value().i16()) then
        _int8(i_16)
      else
        _int16(i_16)
      end

    fun ref i32(i_32: I32 box) =>
      if (i_32 > _null.i32()) and (i_32 > _minus32.i32()) then
        _neg_fixnum(i_32)
      elseif (i_32 <= I8.max_value().i32()) and (i_32 >= I8.min_value().i32()) then
        _int8(i_32)
      elseif (i_32 <= I16.max_value().i32()) and (i_32 >= I16.min_value().i32()) then
        _int16(i_32)
      else
        _int32(i_32)
      end

    fun ref i64(i_64: I64 box) =>
      if (i_64 > _null.i64()) and (i_64 > _minus32.i64()) then
        _neg_fixnum(i_64)
      elseif (i_64 <= I8.max_value().i64()) and (i_64 >= I8.min_value().i64()) then
        _int8(i_64)
      elseif (i_64 <= I16.max_value().i64()) and (i_64 >= I16.min_value().i64()) then
        _int16(i_64)
      elseif (i_64 <= I32.max_value().i64()) and (i_64 >= I32.min_value().i64()) then
        _int32(i_64)
      else
        _int64(i_64)
      end

    fun ref i128(i_128: I128 box): None ? =>
      if (i_128 > _null.i128()) and (i_128 > _minus32.i128()) then
        _neg_fixnum(i_128)
      elseif (i_128 <= I8.max_value().i128()) and (i_128 >= I8.min_value().i128()) then
        _int8(i_128)
      elseif (i_128 <= I16.max_value().i128()) and (i_128 >= I16.min_value().i128()) then
        _int16(i_128)
      elseif (i_128 <= I32.max_value().i128()) and (i_128 >= I32.min_value().i128()) then
        _int32(i_128)
      elseif (i_128 <= I64.max_value().i128()) and (i_128 >= I64.min_value().i128()) then
        _int64(i_128)
      else
        error
      end

    fun ref f32(f: F32 box) =>
      _float32(f)

    fun ref f64(f: F64 box) =>
      _float64(f)

    fun ref string(s: String): None ? =>
      """we need a val here"""
      let size = s.size()
      if size <= USize(31) then
        _fixstr(s)
      elseif size <= U8.max_value().usize() then
        _str8(s)
      elseif size <= U16.max_value().usize() then
        _str16(s)
      elseif size <= U32.max_value().usize() then
        _str32(s)
      else
        // bigger strings are not supported
        error
      end

    fun ref byteseq(b: ByteSeq): None ? =>
      let size = b.size()
      if size <= U8.max_value().usize() then
        _bin8(b)
      elseif size <= U16.max_value().usize() then
        _bin16(b)
      elseif size <= U32.max_value().usize() then
        _bin32(b)
      else
        error
      end


    fun ref array(a: ReadSeq[MsgPackable] box) =>
      """
      """
      // write header
      // iterate through elements, calling pack

    // FORMATS
    fun ref _pos_fixnum(u: Unsigned box) =>
      _writer.u8(u.u8())

    fun ref _uint8(u: Unsigned box) =>
      _writer.u8(0xcc)
      _writer.u8(u.u8())

    fun ref _uint16(u: Unsigned box) =>
      _writer.u8(0xcd)
      _writer.u16_be(u.u16())

    fun ref _uint32(u: Unsigned box) =>
      _writer.u8(0xce)
      _writer.u32_be(u.u32())

    fun ref _uint64(u: Unsigned box) =>
      _writer.u8(0xcf)
      _writer.u64_be(u.u64())

    fun ref _neg_fixnum(s: Signed box) =>
      _writer.u8(
        (s.i32() or I32(224)).u8())

    fun ref _int8(s: Signed box) =>
      _writer.u8(0xd0)
      _writer.u8(s.u8())

    fun ref _int16(s: Signed box) =>
      _writer.u8(0xd1)
      _writer.i16_be(s.i16())

    fun ref _int32(s: Signed box) =>
      _writer.u8(0xd2)
      _writer.i32_be(s.i32())

    fun ref _int64(s: Signed box) =>
      _writer.u8(0xd3)
      _writer.i64_be(s.i64())

    fun ref _float32(f: Float box) =>
      _writer.u8(0xca)
      _writer.f32_be(f.f32())

    fun ref _float64(f: Float box) =>
      _writer.u8(0xcb)
      _writer.f64_be(f.f64())

    fun ref _fixstr(s: String val) =>
      """
      we need a val here as Writer.write(...) wants one
      """
      _writer.u8(s.size().u8() or 160)
      _writer.write(s)

    fun ref _str8(s: String val) =>
      _writer.u8(0xd9)
      _writer.u8(s.size().u8())
      _writer.write(s)

    fun ref _str16(s: String val) =>
      _writer.u8(0xda)
      _writer.u16_be(s.size().u16())
      _writer.write(s)

    fun ref _str32(s: String val) =>
      _writer.u8(0xdb)
      _writer.u32_be(s.size().u32())
      _writer.write(s)

    fun ref _bin8(b: ByteSeq val) =>
      _writer.u8(0xc4)
      _writer.u8(b.size().u8())
      _writer.write(b)

    fun ref _bin16(b: ByteSeq val) =>
      _writer.u8(0xc5)
      _writer.u16_be(b.size().u16())
      _writer.write(b)

    fun ref _bin32(b: ByteSeq val) =>
      _writer.u8(0xc6)
      _writer.u32_be(b.size().u32())
      _writer.write(b)

actor Main
  """
  Types
  Integer represents an integer
  Nil represents nil
  Boolean represents true or false
  Float represents a IEEE 754 double precision floating point number including NaN and Infinity
  Raw
  String extending Raw type represents a UTF-8 string
  Binary extending Raw type represents a byte array
  Array represents a sequence of objects
  Map represents key-value pairs of objects
  Extension represents a tuple of type information and a byte array where type information is an integer whose meaning is defined by applications
  """
  let _env: Env
  let _packer: MsgPacker ref = MsgPacker

  let printValues: Array[MsgPackable] = [ as MsgPackable:
    None
    false
    true
    U32(1)
    U8.min_value()
    U8.max_value()
    U16.min_value()
    U16.max_value()
    U32.min_value()
    U32.max_value()
    U64.min_value()
    U64.max_value()
    U128.min_value()
    U128.max_value()
    I32(-1)
    I8.min_value()
    I8.max_value()
    I16.min_value()
    I16.max_value()
    I32.min_value()
    I32.max_value()
    I64.min_value()
    I64.max_value()
    I128.min_value()
    "abcdef"
    recover val [as U8: 0x01; 0x02; 0x03] end
    //recover val [as I32: 0x01; 0x02; 0x03] end
  ]

    new create(env: Env) =>
      _env = env
      printExampleValues()

    fun ref msgPackPrint(msg: MsgPackable): String =>
      try
        let a: Array[U8 val] = _packer.pack(msg) as Array[U8 val]
        printHexArray(a)
      else
        "ERROR"
      end

    fun printHexArray(a: Array[U8]): String =>
      let hexStrs =
        Iter[U8](a.values())
          .map[String]({(n: U8): String => Format.int[U8](n where fmt = FormatHex)})
          .collect(Array[String](a.size()))
      "[" + ",".join(hexStrs) + "]"

    fun ref printExampleValues(): None =>
      for value in printValues.values() do
        let hexStr = msgPackPrint(value)
        _env.out.print(hexStr)
      end


