package main

import (
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"time"

	"github.com/metacubex/mihomo/log"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

const (
	// f6IdleGCStep is how often the guard samples the traffic counters.
	f6IdleGCStep = 5 * time.Second
	// f6IdleGCThreshold skips the forced GC when there is nothing worth returning.
	// FreeOSMemory is a full stop-the-world GC, so it must not run on a small heap.
	f6IdleGCThreshold = 16 << 20
	// f6IdleGCCooldown bounds how often a forced GC may run while the tunnel is
	// quiet for a long time (every QUIC keepalive resets the idle timer).
	f6IdleGCCooldown = 5 * time.Minute
)

// startF6MemoryGuard returns the heap to the OS once the tunnel goes quiet.
//
// Go's scavenger releases pages lazily (minutes of pacing), so a client that
// bursts to a few hundred connections keeps that high-water mark for the rest
// of the session. Opt in with F6_IDLE_GC_SEC=N: after N seconds without a byte
// of traffic, run a full GC and FreeOSMemory once.
//
// The trigger is traffic, not connection count: with 28 masque nodes each
// holding a remote-DNS socket, the connection table never reaches zero even
// when the machine is idle (measured: a lingering "Inner" UDP session to 1.1.1.1).
//
// Measured on the shipped 28-node config: 105 MB -> 59 MB after a burst of
// 1000 connections, i.e. everything the scavenger had not returned yet.
func startF6MemoryGuard() {
	sec, err := strconv.Atoi(os.Getenv("F6_IDLE_GC_SEC"))
	if err != nil || sec <= 0 {
		return
	}
	timeout := time.Duration(sec) * time.Second
	log.Infoln("[f6] idle GC enabled: return freed heap to the OS after %ds without traffic", sec)

	go func() {
		ticker := time.NewTicker(f6IdleGCStep)
		defer ticker.Stop()

		lastUp, lastDown := statistic.DefaultManager.Total()
		var quiet time.Duration
		var lastFire time.Time
		for range ticker.C {
			up, down := statistic.DefaultManager.Total()
			moved := (up - lastUp) + (down - lastDown)
			lastUp, lastDown = up, down

			if moved != 0 {
				quiet = 0
				continue
			}
			quiet += f6IdleGCStep
			if quiet < timeout || time.Since(lastFire) < f6IdleGCCooldown {
				continue
			}

			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			returnable := m.HeapIdle - m.HeapReleased
			if returnable < f6IdleGCThreshold {
				continue
			}
			debug.FreeOSMemory()
			lastFire = time.Now()
			quiet = 0
			log.Infoln("[f6] idle %ds, returned %d MB of freed heap to the OS", sec, returnable>>20)
		}
	}()
}
