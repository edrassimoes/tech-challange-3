package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func enabledFlag() *Flag {
	return &Flag{Name: "new-dashboard", IsEnabled: true}
}

func percentageRule(value float64) *TargetingRule {
	return &TargetingRule{IsEnabled: true, Rules: Rule{Type: "PERCENTAGE", Value: value}}
}

func TestRunEvaluationLogic(t *testing.T) {
	app := &App{}

	tests := []struct {
		name string
		info *CombinedFlagInfo
		want bool
	}{
		{"flag desativada", &CombinedFlagInfo{Flag: &Flag{Name: "new-dashboard"}, Rule: percentageRule(100)}, false},
		{"flag sem regra", &CombinedFlagInfo{Flag: enabledFlag()}, true},
		{"regra em 100%", &CombinedFlagInfo{Flag: enabledFlag(), Rule: percentageRule(100)}, true},
		{"regra em 0%", &CombinedFlagInfo{Flag: enabledFlag(), Rule: percentageRule(0)}, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := app.runEvaluationLogic(tt.info, "user-1"); got != tt.want {
				t.Errorf("got %t, want %t", got, tt.want)
			}
		})
	}
}

func TestGetDeterministicBucket(t *testing.T) {
	first := getDeterministicBucket("user-1new-dashboard")

	if first != getDeterministicBucket("user-1new-dashboard") {
		t.Error("o bucket deve ser determinístico")
	}
	if first < 0 || first > 99 {
		t.Errorf("bucket fora do intervalo: %d", first)
	}
}

func TestFetchFromServicesFailsWhenTargetingIsDown(t *testing.T) {
	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"name": "new-dashboard", "is_enabled": true}`))
	}))
	defer flagServer.Close()

	targetingServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer targetingServer.Close()

	app := &App{
		HttpClient:          http.DefaultClient,
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: targetingServer.URL,
	}

	if _, err := app.fetchFromServices("new-dashboard"); err == nil {
		t.Error("deveria falhar quando o targeting-service está indisponível")
	}
}

func TestFetchFromServicesWithoutRule(t *testing.T) {
	flagServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"name": "new-dashboard", "is_enabled": true}`))
	}))
	defer flagServer.Close()

	targetingServer := httptest.NewServer(http.NotFoundHandler())
	defer targetingServer.Close()

	app := &App{
		HttpClient:          http.DefaultClient,
		FlagServiceURL:      flagServer.URL,
		TargetingServiceURL: targetingServer.URL,
	}

	info, err := app.fetchFromServices("new-dashboard")
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if info.Rule != nil {
		t.Error("a regra deveria ser nula")
	}
}
