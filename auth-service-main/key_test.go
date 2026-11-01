package main

import (
	"strings"
	"testing"
)

func TestGenerateAPIKey(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if !strings.HasPrefix(key, "tm_key_") {
		t.Errorf("chave sem o prefixo esperado: %s", key)
	}
}

func TestHashAPIKey(t *testing.T) {
	want := "8f2e895eb556e60f9ccfd8cd8e754d5379ef320570fd47a8307e73968a10c3eb"

	if got := hashAPIKey("local-service-key"); got != want {
		t.Errorf("got %s, want %s", got, want)
	}
}
