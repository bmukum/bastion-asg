package test

import (
	"testing"

	"github.com/RedVentures/terraform-abstraction/testutils"
)

func TestModule(t *testing.T) {
	testutils.RunAllTerratests(t, ".")
}
