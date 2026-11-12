// sha-tool: a Bentra module action as a static Go binary. It reads the step's inputs from
// $BENTRA_INPUT_FILE and writes one JSON object to $BENTRA_OUTPUT_FILE.
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
)

type input struct {
	Text string `json:"text"`
}

type output struct {
	SHA256 string `json:"sha256"`
	Bytes  int    `json:"bytes"`
}

func main() {
	raw, err := os.ReadFile(os.Getenv("BENTRA_INPUT_FILE"))
	if err != nil {
		fail("read inputs: %v", err)
	}
	var in input
	if err := json.Unmarshal(raw, &in); err != nil {
		fail("parse inputs: %v", err)
	}
	sum := sha256.Sum256([]byte(in.Text))
	out, _ := json.Marshal(output{SHA256: hex.EncodeToString(sum[:]), Bytes: len(in.Text)})
	if err := os.WriteFile(os.Getenv("BENTRA_OUTPUT_FILE"), out, 0o600); err != nil {
		fail("write outputs: %v", err)
	}
	fmt.Printf("hashed %d bytes\n", len(in.Text))
}

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
