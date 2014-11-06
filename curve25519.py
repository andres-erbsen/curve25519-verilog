# Written by Andres Erbsen on 2014-11-06
# Public Domain + CC0

P = (2**255 - 19)
A_MINUS_TWO_OVER_FOUR = 121665
BASE = bytes([9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

def curve25519_mult(n, q):
    mx, mz = q, 1
    sx, sz = 1, 0
    psx, pmx = 0, 0

    # prepare first round
    psx = sx
    sx = (sx + sz) % P
    pmx = mx
    mx = (mx + mz) % P

    for i in range(254, -1, -1):
        if (n >> i) & 1 != (n >> (i+1)) & 1:
            psx, sx, sz, pmx, mx, mz = pmx, mx, mz, psx, sx, sz

        # stage 1
        psx, sx, sz = sx, sx * sx % P, (psx - sz) % P

        # stage 2
        psz = sz
        sz = sz * sz % P

        # stage 3
        mx = mx * psz % P
        mz = (pmx - mz) % P

        # stage 4
        psz = sz
        sz = (sx - sz) % P
        mz = mz * psx % P

        # stage 5
        psx = sx
        sx = sx * psz % P
        pmx = mx
        mx = (mx + mz) % P

        # stage 6
        psz = sz
        sz = sz * A_MINUS_TWO_OVER_FOUR % P
        mz = (mz - pmx) % P

        # stage 7
        sz = (sz + psx) % P
        mx = mx * mx % P

        # stage 8
        sz = sz * psz % P

        # stage 9
        mz = mz * mz % P
        # prrepare next round
        psx = sx
        sx = (sx + sz) % P

        # stage 10
        mz = mz * q % P
        # prrepare next round
        pmx = mx
        mx = (mx + mz) % P

    # lowest bit of the scalar is always 0, so no need to swap back
    return psx * pow(sz, P-2, P) % P

def curve25519(scalar, point):
    scalar[0] &= 248
    scalar[31] &= 127
    scalar[31] |= 64
    s = int.from_bytes(scalar, 'little')
    p = int.from_bytes(point, 'little')
    return bytearray(curve25519_mult(s, p).to_bytes(32, 'little'))

if __name__ == '__main__':
    # test from https://code.google.com/p/go/source/browse/curve25519/doc.go?repo=crypto
    a = bytearray(32)
    a[0] = 1
    for i in range(200):
        a, b = curve25519(a, BASE), a

    expected = '89161fde887b2b53de549af483940106ecc114d6982daa98256de23bdf77661a'
    assert a == bytes.fromhex(expected)

