use "ponytest"
use msgpack = ".."

primitive MsgPackSerialization

    fun msgPackSafe(a: msgpack.MsgPackable): Array[U8 val] val ? =>
        match msgpack.MsgPack.serialize(a)
        | None => error
        | let msgPacked: Array[U8 val] val => msgPacked
        else
            error
        end

class iso _MsgPackSerializationBoolTest is UnitTest
    fun name(): String => "msgpack/serialization/bool"


    fun apply(h: TestHelper) =>
        try
            h.assert_array_eq[U8 val](
                MsgPackSerialization.msgPackSafe(true),
                recover [as U8: 0xc2] end
            )
            h.assert_array_eq[U8 val](
                MsgPackSerialization.msgPackSafe(false),
                recover [as U8: 0xc3] end
            )
            h.assert_error(
                object is ITest
                    fun apply(): None val ? =>
                        MsgPackSerialization.msgPackSafe(U128.max_value())
                end
            )
        end

class iso _MsgPackSerializationNoneTest is UnitTest
    fun name(): String => "msgpack/serialization/none"

    fun apply(h: TestHelper) =>
        try
            h.assert_array_eq[U8 val](
                MsgPackSerialization.msgPackSafe(None),
                recover [as U8: 0xc0 ] end
            )
        end
