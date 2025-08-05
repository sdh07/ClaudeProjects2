# ADR-005: Multi-Layer Context Cache Strategy

**Status**: Accepted  
**Date**: 2025-08-05  
**Decision Makers**: Architecture Team  
**Related Issues**: #24, #25

## Context

Context switching is critical for agent performance. Our target is < 500ms for full context switches. Analysis shows:

- Working contexts: 1-10KB (accessed frequently)
- Project contexts: 10-100KB (accessed moderately)  
- Learning contexts: 100KB-1MB (accessed occasionally)
- Knowledge contexts: 1-10MB (accessed rarely)

Traditional caching approaches don't account for these different access patterns and sizes.

## Decision

We will implement a **multi-layer cache architecture**:

1. **L1 Hot Cache**: In-memory, 10-50 contexts, < 10ms access
2. **L2 Warm Cache**: Compressed memory, 100-500 contexts, < 50ms access
3. **L3 Cold Cache**: Disk-based, 1000+ contexts, < 200ms access
4. **L4 Storage**: File system, all contexts, < 500ms access

Additionally:
- Predictive pre-loading based on access patterns
- Context-aware compression strategies
- Lazy loading for large context sections

## Consequences

### Positive
- **Fast Access**: 80%+ requests served from L1/L2
- **Memory Efficient**: Compression reduces memory usage
- **Scalable**: Handles thousands of contexts
- **Predictable**: Consistent performance
- **Intelligent**: Learns access patterns

### Negative
- **Complex Implementation**: Multiple cache layers
- **Memory Overhead**: Caching infrastructure
- **Consistency**: Cache invalidation challenges
- **Tuning Required**: Needs optimization per deployment

### Neutral
- Requires monitoring and metrics
- Cache warming on startup
- Periodic maintenance tasks

## Implementation

### Cache Hierarchy
```typescript
class ContextCacheManager {
  private l1: HotCache;      // LRU, uncompressed
  private l2: WarmCache;     // LFU, compressed
  private l3: ColdCache;     // File-based, indexed
  private predictor: AccessPredictor;
  
  async get(contextId: string): Promise<Context> {
    // Try each layer
    return await this.l1.get(contextId) ||
           await this.l2.get(contextId) ||
           await this.l3.get(contextId) ||
           await this.loadFromDisk(contextId);
  }
}
```

### Compression Strategy
```typescript
interface CompressionStrategy {
  fast: {
    algorithm: 'lz4',
    level: 1,
    ratio: 0.7,
    speed: '100MB/s'
  },
  balanced: {
    algorithm: 'gzip', 
    level: 6,
    ratio: 0.5,
    speed: '50MB/s'
  },
  maximum: {
    algorithm: 'brotli',
    level: 11,
    ratio: 0.3,
    speed: '10MB/s'
  }
}

// Context-aware selection
function selectCompression(section: string, size: number) {
  if (section === 'workingDirectory') return 'fast';
  if (size > 1000000) return 'maximum';
  return 'balanced';
}
```

### Predictive Loading
```typescript
class PredictiveLoader {
  private transitions: Map<string, Map<string, number>>;
  
  async onContextSwitch(from: string, to: string) {
    // Record transition
    this.recordTransition(from, to);
    
    // Predict next contexts
    const predictions = this.predictNext(to, 3);
    
    // Preload in background
    for (const contextId of predictions) {
      this.preloadToL2(contextId);
    }
  }
}
```

## Performance Metrics

### Target Cache Hit Rates
- L1: 40% (hot working set)
- L2: 30% (recent contexts)
- L3: 10% (historical contexts)
- Disk: 20% (cold contexts)
- **Overall**: 80% cache hit rate

### Latency Targets
| Operation | P50 | P95 | P99 |
|-----------|-----|-----|-----|
| Context Load | 15ms | 100ms | 200ms |
| Context Switch | 50ms | 300ms | 450ms |
| Cache Hit (L1) | 2ms | 5ms | 10ms |
| Cache Hit (L2) | 10ms | 30ms | 45ms |

## Memory Management

### Eviction Policies
```typescript
interface EvictionPolicy {
  l1: 'LRU',        // Least Recently Used
  l2: 'LFU',        // Least Frequently Used  
  l3: 'TTL+Size',   // Time + Size based
}

interface MemoryLimits {
  l1: 50_000_000,   // 50MB
  l2: 200_000_000,  // 200MB compressed
  l3: 1_000_000_000 // 1GB disk
}
```

## Alternatives Considered

### 1. Single-Layer Memory Cache
- Simple LRU cache
- Rejected: Insufficient for large contexts

### 2. Database-Backed Cache
- Redis/SQLite caching
- Rejected: Added dependency, slower

### 3. Memory-Mapped Files
- OS-level caching
- Rejected: Platform-specific, less control

### 4. No Caching
- Always read from disk
- Rejected: Cannot meet performance targets

## Monitoring

```typescript
interface CacheMetrics {
  hitRate: { l1: number; l2: number; l3: number };
  latency: { p50: number; p95: number; p99: number };
  evictions: number;
  memoryUsage: number;
  predictions: {
    accuracy: number;
    preloadHits: number;
  };
}
```

## References

- [Context Layer Performance Optimization](../03-physical-architecture/Context-Layer-Performance.md)
- LRU/LFU cache implementations
- Compression algorithm benchmarks

## Review

Review monthly with performance metrics to tune cache sizes and eviction policies.