# Written by Andres Erbsen on 2014-11-06
# Public Domain + CC0

P = (2**255 - 19)
A_MINUS_TWO_OVER_FOUR = 121665
BASE = bytes([9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

def curve25519_mult(n, q):
    sx, sz = 1, 0
    mx, mz = q, 1

    # prepare first round
    psx = sx
    pmx = mx

    mx = (mx + mz) % P

    for i in range(254, -1, -1):
        if (n >> i) & 1 != (n >> (i+1)) & 1:
            psx, sx, sz, pmx, mx, mz = pmx, mx, mz, psx, sx, sz

        # stage 1
        psx, sx, sz = sx, sx * sx % P, (psx - sz) % P
        # stage 1.5
        pipeline_sz = sz * sz % P

        # stage 2
        pipeline_mx = mx * sz % P
        psz = sz
        mz = (pmx - mz) % P
        sz = sz * sz % P; assert(sz == pipeline_sz)

        # stage 3
        pipeline_mz = mz * psx % P
        mx = mx * psz % P; assert(mx == pipeline_mx)

        # stage 4
        pipeline_sx = sx * sz % P
        psz = sz
        sz = (sx - sz) % P
        mz = mz * psx % P; assert(pipeline_mz == mz)

        # stage 5
        pipeline_sz = sz * A_MINUS_TWO_OVER_FOUR % P
        pmx = mx
        mx = (mx + mz) % P
        psx = sx
        sx = sx * psz % P; assert(pipeline_sx == sx) % P

        # stage 6
        pipeline_mx = mx * mx % P
        psz = sz
        mz = (mz - pmx) % P
        sz = sz * A_MINUS_TWO_OVER_FOUR % P; assert(pipeline_sz == sz)

        # stage 7
        pipeline_mz = mz * mz % P
        sz = (sz + psx) % P
        mx = mx * mx % P; assert(pipeline_mx == mx)

        # stage 8
        pipeline_sz = sz * psz % P
        mz = mz * mz % P; assert(pipeline_mz == mz)

        # stage 9
        pipeline_mz = mz * q % P
        sz = sz * psz % P; assert(pipeline_sz == sz)
        # prrepare next round
        psx = sx

        # stage 10
        mz = mz * q % P; assert(pipeline_mz == mz)
        sx = (sx + sz) % P

        # stage 11
        # prepare next round
        pmx = mx
        mx = (mx + mz) % P

        print("assert( sx == 0x%32x)"%  sx);
        print("assert( sz == 0x%32x)"%  sz);
        print("assert( mx == 0x%32x)"%  mx);
        print("assert( mz == 0x%32x)"%  mz);
        print("assert(psx == 0x%32x)"% psx);
        print("assert(psz == 0x%32x)"% psz);
        print("assert(pmx == 0x%32x)"% pmx);

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

