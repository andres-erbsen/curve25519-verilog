package main

import (
	"code.google.com/p/go.crypto/curve25519"
	"fmt"
)

var base = [32]byte{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

func variable() {
	secret := [32]byte{
		32, 31, 30, 29, 28, 27, 26, 25,
		24, 23, 22, 21, 20, 19, 18, 17,
		16, 15, 14, 13, 12, 11, 10, 9,
		8, 7, 6, 5, 4, 3, 2, 64,
	}

	var public, shared [32]byte
	curve25519.ScalarMult(&public, &secret, &base)
	curve25519.ScalarMult(&shared, &secret, &public)

	fmt.Printf("minimal:\n")
	fmt.Printf("public: %x\n", public)
	fmt.Printf("shared: %x\n", shared)
}

func minimal() {
	secret := [32]byte{
		1, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
	}

	var public, shared [32]byte
	curve25519.ScalarMult(&public, &secret, &base)
	curve25519.ScalarMult(&shared, &secret, &public)

	fmt.Printf("variable:\n")
	fmt.Printf("public: %x\n", public)
	fmt.Printf("shared: %x\n", shared)
}

func dh_test() {
	a := [32]byte{0x20, 0x35, 0x15, 0x12, 0x81, 0x5e, 0x89, 0xc0, 0x09, 0xd6, 0x84, 0x84, 0x63, 0x56, 0xf0, 0xb1, 0x0d, 0x7b, 0xb9, 0x06, 0x8d, 0x99, 0xdf, 0x46, 0x65, 0x84, 0xc2, 0xb2, 0x12, 0x52, 0x37, 0x49}
	b := [32]byte{0x00, 0xe3, 0xf3, 0x00, 0x0d, 0xcd, 0xd7, 0x06, 0x76, 0xf1, 0x23, 0x3b, 0x3d, 0xcd, 0x8d, 0x1e, 0xed, 0x57, 0xd4, 0x76, 0x8c, 0xf7, 0x2d, 0x46, 0xf9, 0xe9, 0xfd, 0x7c, 0xc6, 0x24, 0x37, 0x63}

	var A, B, shared_a, shared_b [32]byte
	curve25519.ScalarMult(&A, &a, &base)
	curve25519.ScalarMult(&B, &b, &base)
	curve25519.ScalarMult(&shared_a, &a, &B)
	curve25519.ScalarMult(&shared_b, &b, &A)

	fmt.Printf("dh_test:\n")
	fmt.Printf("a: %x\n", a)
	fmt.Printf("a: %x\n", a)
	fmt.Printf("A: %x\n", A)
	fmt.Printf("B: %x\n", B)
	fmt.Printf("shared_a: %x\n", shared_a)
	fmt.Printf("shared_b: %x\n", shared_b)
}

func main() {
	minimal()
	variable()
	dh_test()
}
