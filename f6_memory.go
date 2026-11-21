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
	// f6IdleGCConns treats a handful of connections as idle: the masque nodes
	// keep one remote-DNS socket each, and Windows keeps polling for
	// connectivity, so a busy desktop rarely reaches exactly zero.
	f6IdleGCConns = 2
	// f6IdleGCBytes is the traffic below which a window counts as quiet.
	// 8 KB per 5 s window (~1.6 KB/s) leaves room for keepalive pings and
	// telemetry while still ignoring an idle browser tab.
	f6IdleGCBytes = 8 << 10
)

// startF6MemoryGuard returns the heap to the OS once the tunnel goes quiet.
//
// Go's scavenger releases pages lazily (minutes of pacing), so a client that
// bursts to a few hundred connections keeps that high-water mark for the rest
// of the session. Opt in with F6_IDLE_GC_SEC=N: after N seconds of quiet, run a
// full GC and FreeOSMemory once.
//
// "Quiet" means either less than f6IdleGCBytes of traffic in the window, or a
// connection table of at most f6IdleGCConns entries. Both signals are needed:
// trackers linger for tens of seconds after the last close (so traffic is the
// earlier signal), while a few long-lived sockets with pings never look idle by
// byte count alone (so the connection count is the more robust one).
//
// Measured on the shipped 28-node config: 105 MB -> 55.6 MB after a burst of
// 1000 connections, i.e. everything the scavenger had not returned yet.
func startF6MemoryGuard() {
	sec, err := strconv.Atoi(os.Getenv("F6_IDLE_GC_SEC"))
	if err != nil || sec <= 0 {
		return
	}
	timeout := time.Duration(sec) * time.Second
	log.Infoln("[f6] idle GC enabled: return freed heap to the OS after %ds of quiet", sec)

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

			if moved >= f6IdleGCBytes && f6ConnectionCount() > f6IdleGCConns {
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

func f6ConnectionCount() int {
	n := 0
	statistic.DefaultManager.Range(func(statistic.Tracker) bool {
		n++
		return n <= f6IdleGCConns // stop as soon as we know it is busy
	})
	return n
}
