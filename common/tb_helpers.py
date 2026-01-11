import math

def decode_packed_struct(logic_array, fields):
    """
    Decode a packed struct bitvector into named fields.

    Args:
        logic_array: An object representing a logic array of 1s/0s. Must support str(logic_array),
                     producing a string of bits (e.g. "0101...").
        fields: List[tuple[str, int]] in LSB->MSB order. Each tuple is (field_name, field_width).

    Returns:
        dict[str, str]: {field_name: bit_substring}, where each value is the slice of the bitstring
                        corresponding to that field's offset/width.

    Notes:
        - This returns substrings from the string representation of logic_array.
    """
    bits = str(logic_array).strip().replace("_", "").replace(" ", "")

    # Basic validation
    if not bits:
        raise ValueError("logic_array string representation is empty")

    for ch in bits:
        if ch not in ("0", "1"):
            raise ValueError(f"logic_array contains non-bit character: {ch!r}")

    total_width = 0
    for name, width in fields:
        if not isinstance(name, str) or not name:
            raise ValueError(f"Invalid field name: {name!r}")
        if not isinstance(width, int) or width <= 0:
            raise ValueError(f"Invalid width for field {name!r}: {width!r}")
        total_width += width

    if len(bits) < total_width:
        raise ValueError(
            f"logic_array has {len(bits)} bits, but fields require {total_width} bits"
        )

    # Use only the least-significant total_width bits if extra bits are present
    bits = bits[-total_width:]

    # Rightmost char is LSB. For a field at LSB offset 'off' with width 'w':
    # slice indices are [-(off+w) : -off] (with -0 handled as end of string)
    out = {}
    off = 0
    for name, width in fields:
        start = total_width - (off + width)
        end = total_width - off
        out[name] = bits[start:end]
        off += width

    return out

def clog2(x):
    return int(math.ceil(math.log2(x)))
