# Obsidian Integration Edge Cases
**Sprint 2, Thursday - Issue #25**
**Date**: 2025-08-05

## Executive Summary

This document addresses the complex edge cases that arise when integrating ClaudeProjects2 with Obsidian. These edge cases include handling concurrent edits, large vault performance, plugin compatibility, and graceful degradation when the MCP server fails.

## Critical Edge Cases

### 1. Concurrent Edit Conflicts
- User editing in Obsidian while agent modifies same file
- Multiple agents modifying same note simultaneously
- Obsidian's auto-save conflicting with agent writes

### 2. Large Vault Performance
- Vaults with 10,000+ notes
- Large individual notes (>1MB)
- Complex graph relationships

### 3. Plugin Compatibility
- Conflicts with popular Obsidian plugins
- API limitations and workarounds
- Plugin-modified content handling

### 4. MCP Server Failures
- Connection timeouts
- API rate limiting
- Server crashes and recovery

## Concurrent Edit Resolution

### 1. File Locking Strategy

```typescript
class ObsidianFileLock {
  private locks: Map<string, FileLock> = new Map();
  private obsidianActiveFiles: Set<string> = new Set();
  
  async acquireLock(
    filePath: string, 
    agentId: string,
    options: LockOptions = {}
  ): Promise<LockResult> {
    const lockKey = this.normalizePath(filePath);
    
    // Check if Obsidian has the file open
    if (this.obsidianActiveFiles.has(lockKey)) {
      if (options.waitForObsidian) {
        return await this.waitForObsidianClose(lockKey, options.timeout);
      } else {
        return {
          success: false,
          reason: 'file_open_in_obsidian',
          suggestion: 'defer_write'
        };
      }
    }
    
    // Check for existing locks
    const existingLock = this.locks.get(lockKey);
    if (existingLock && !this.isLockExpired(existingLock)) {
      return {
        success: false,
        reason: 'locked_by_agent',
        lockedBy: existingLock.agentId,
        expiresAt: existingLock.expiresAt
      };
    }
    
    // Acquire lock
    const lock: FileLock = {
      filePath: lockKey,
      agentId,
      acquiredAt: Date.now(),
      expiresAt: Date.now() + (options.duration || 5000),
      type: options.exclusive ? 'exclusive' : 'shared'
    };
    
    this.locks.set(lockKey, lock);
    
    return {
      success: true,
      lock,
      release: () => this.releaseLock(lockKey, agentId)
    };
  }
  
  private async waitForObsidianClose(
    filePath: string, 
    timeout: number = 30000
  ): Promise<LockResult> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
      if (!this.obsidianActiveFiles.has(filePath)) {
        // File closed, try to acquire lock
        return this.acquireLock(filePath, 'waiting-agent');
      }
      
      // Wait and retry
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    return {
      success: false,
      reason: 'timeout_waiting_for_obsidian'
    };
  }
}
```

### 2. Conflict Detection

```typescript
class ConflictDetector {
  async detectConflict(
    filePath: string,
    agentContent: string,
    agentLastModified: number
  ): Promise<ConflictInfo | null> {
    // Get current file state
    const currentStats = await fs.stat(filePath);
    const currentContent = await fs.readFile(filePath, 'utf-8');
    
    // Check if file was modified after agent read it
    if (currentStats.mtimeMs > agentLastModified) {
      // Check if content actually differs
      if (currentContent !== agentContent) {
        return {
          type: 'concurrent_modification',
          fileModified: new Date(currentStats.mtimeMs),
          agentRead: new Date(agentLastModified),
          hasContentDifference: true,
          resolution: await this.suggestResolution(currentContent, agentContent)
        };
      }
    }
    
    // Check for Obsidian metadata conflicts
    const metadataConflict = this.checkMetadataConflict(currentContent, agentContent);
    if (metadataConflict) {
      return metadataConflict;
    }
    
    return null;
  }
  
  private checkMetadataConflict(current: string, proposed: string): ConflictInfo | null {
    const currentMeta = this.extractYamlFrontmatter(current);
    const proposedMeta = this.extractYamlFrontmatter(proposed);
    
    // Check for conflicting tags, aliases, etc.
    if (currentMeta && proposedMeta) {
      const conflicts = this.compareMetadata(currentMeta, proposedMeta);
      if (conflicts.length > 0) {
        return {
          type: 'metadata_conflict',
          conflicts,
          resolution: 'merge_metadata'
        };
      }
    }
    
    return null;
  }
}
```

### 3. Three-Way Merge

```typescript
class ThreeWayMerge {
  async merge(
    originalContent: string,
    obsidianContent: string,
    agentContent: string
  ): Promise<MergeResult> {
    // Split content into sections
    const originalSections = this.splitIntoSections(originalContent);
    const obsidianSections = this.splitIntoSections(obsidianContent);
    const agentSections = this.splitIntoSections(agentContent);
    
    const mergedSections: Section[] = [];
    const conflicts: MergeConflict[] = [];
    
    // Merge each section
    for (let i = 0; i < Math.max(
      originalSections.length,
      obsidianSections.length,
      agentSections.length
    ); i++) {
      const original = originalSections[i];
      const obsidian = obsidianSections[i];
      const agent = agentSections[i];
      
      if (!original) {
        // New section added
        if (obsidian && agent && obsidian.content !== agent.content) {
          conflicts.push({
            section: i,
            type: 'both_added_different',
            obsidianContent: obsidian.content,
            agentContent: agent.content
          });
        } else {
          mergedSections.push(obsidian || agent);
        }
      } else if (obsidian?.content === original.content && agent?.content !== original.content) {
        // Only agent modified
        mergedSections.push(agent || original);
      } else if (agent?.content === original.content && obsidian?.content !== original.content) {
        // Only Obsidian modified
        mergedSections.push(obsidian || original);
      } else if (obsidian?.content === agent?.content) {
        // Both made same change
        mergedSections.push(obsidian || original);
      } else {
        // Conflict
        conflicts.push({
          section: i,
          type: 'both_modified_different',
          originalContent: original?.content,
          obsidianContent: obsidian?.content,
          agentContent: agent?.content
        });
      }
    }
    
    if (conflicts.length === 0) {
      return {
        success: true,
        content: this.combineSection(mergedSections),
        conflicts: []
      };
    } else {
      return {
        success: false,
        content: null,
        conflicts,
        suggestion: await this.generateConflictResolution(conflicts)
      };
    }
  }
  
  private splitIntoSections(content: string): Section[] {
    const sections: Section[] = [];
    const lines = content.split('\n');
    let currentSection: Section = { type: 'text', content: '', start: 0 };
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Detect section boundaries
      if (line.startsWith('# ')) {
        if (currentSection.content) {
          sections.push(currentSection);
        }
        currentSection = { type: 'heading', content: line, start: i };
      } else if (line.startsWith('```')) {
        if (currentSection.content) {
          sections.push(currentSection);
        }
        currentSection = { type: 'code', content: line, start: i };
      } else {
        currentSection.content += (currentSection.content ? '\n' : '') + line;
      }
    }
    
    if (currentSection.content) {
      sections.push(currentSection);
    }
    
    return sections;
  }
}
```

### 4. Real-time Sync Protocol

```typescript
class RealtimeSyncProtocol {
  private fileWatchers: Map<string, fs.FSWatcher> = new Map();
  private pendingChanges: Map<string, PendingChange> = new Map();
  
  async enableRealtimeSync(vaultPath: string): Promise<void> {
    // Watch for Obsidian changes
    const watcher = chokidar.watch(vaultPath, {
      ignored: /(^|[\/\\])\../, // Ignore hidden files
      persistent: true,
      awaitWriteFinish: {
        stabilityThreshold: 200,
        pollInterval: 100
      }
    });
    
    watcher.on('change', (path) => this.handleObsidianChange(path));
    watcher.on('add', (path) => this.handleObsidianAdd(path));
    watcher.on('unlink', (path) => this.handleObsidianDelete(path));
  }
  
  private async handleObsidianChange(filePath: string): Promise<void> {
    // Check if we have pending agent changes
    const pending = this.pendingChanges.get(filePath);
    
    if (pending) {
      // Potential conflict
      const conflict = await this.detectConflict(filePath, pending);
      
      if (conflict) {
        await this.resolveConflict(filePath, pending, conflict);
      }
    }
    
    // Notify agents of external change
    await this.notifyAgentsOfChange(filePath, 'external_modification');
  }
  
  async scheduleAgentWrite(
    filePath: string,
    content: string,
    agentId: string
  ): Promise<void> {
    // Add to pending changes
    this.pendingChanges.set(filePath, {
      content,
      agentId,
      scheduledAt: Date.now(),
      priority: 'normal'
    });
    
    // Try to write after a delay
    setTimeout(async () => {
      const pending = this.pendingChanges.get(filePath);
      if (pending && pending.content === content) {
        await this.executeWrite(filePath, pending);
      }
    }, 500); // Wait 500ms for Obsidian to settle
  }
}
```

## Large Vault Performance

### 1. Indexed Search Strategy

```typescript
class VaultIndexer {
  private index: SearchIndex;
  private fileIndex: Map<string, FileMetadata> = new Map();
  private updateQueue: AsyncQueue<IndexUpdate>;
  
  async buildIndex(vaultPath: string): Promise<void> {
    console.log('Building vault index...');
    const startTime = Date.now();
    
    // Initialize search index
    this.index = new SearchIndex({
      fields: ['title', 'content', 'tags', 'aliases'],
      storeDocuments: false, // Don't store full content
      searchOptions: {
        boost: { title: 2, tags: 1.5 },
        fuzzy: 0.2
      }
    });
    
    // Scan vault in batches
    const files = await this.scanVaultFiles(vaultPath);
    const batchSize = 100;
    
    for (let i = 0; i < files.length; i += batchSize) {
      const batch = files.slice(i, i + batchSize);
      await this.indexBatch(batch);
      
      // Report progress
      if (i % 1000 === 0) {
        console.log(`Indexed ${i}/${files.length} files`);
      }
    }
    
    const duration = Date.now() - startTime;
    console.log(`Index built in ${duration}ms for ${files.length} files`);
  }
  
  private async indexBatch(files: string[]): Promise<void> {
    const documents = await Promise.all(files.map(async (file) => {
      const content = await this.readFileOptimized(file);
      const metadata = this.extractMetadata(content);
      
      // Store minimal metadata
      this.fileIndex.set(file, {
        path: file,
        title: metadata.title,
        size: content.length,
        modified: Date.now(),
        tags: metadata.tags,
        backlinks: metadata.backlinks.length
      });
      
      return {
        id: file,
        title: metadata.title,
        content: this.extractSearchableContent(content),
        tags: metadata.tags.join(' '),
        aliases: metadata.aliases.join(' ')
      };
    }));
    
    // Batch add to index
    this.index.addDocuments(documents);
  }
  
  async search(query: string, options: SearchOptions = {}): Promise<SearchResult[]> {
    const limit = options.limit || 20;
    const searchStart = Date.now();
    
    // Use index for initial search
    const indexResults = this.index.search(query, limit * 2);
    
    // Enhance results with metadata
    const results = await Promise.all(indexResults.slice(0, limit).map(async (result) => {
      const metadata = this.fileIndex.get(result.ref);
      
      return {
        path: result.ref,
        score: result.score,
        title: metadata?.title || 'Untitled',
        excerpt: await this.generateExcerpt(result.ref, query),
        metadata
      };
    }));
    
    const searchDuration = Date.now() - searchStart;
    
    return {
      results,
      totalResults: indexResults.length,
      searchTime: searchDuration,
      cached: true
    };
  }
}
```

### 2. Lazy Loading Strategy

```typescript
class LazyVaultLoader {
  private loadedNotes: LRUCache<string, ParsedNote>;
  private loadingPromises: Map<string, Promise<ParsedNote>> = new Map();
  
  constructor(maxCachedNotes: number = 1000) {
    this.loadedNotes = new LRUCache({ max: maxCachedNotes });
  }
  
  async getNote(path: string): Promise<ParsedNote | null> {
    // Check cache
    if (this.loadedNotes.has(path)) {
      return this.loadedNotes.get(path)!;
    }
    
    // Check if already loading
    if (this.loadingPromises.has(path)) {
      return await this.loadingPromises.get(path)!;
    }
    
    // Start loading
    const loadPromise = this.loadNote(path);
    this.loadingPromises.set(path, loadPromise);
    
    try {
      const note = await loadPromise;
      this.loadedNotes.set(path, note);
      return note;
    } finally {
      this.loadingPromises.delete(path);
    }
  }
  
  private async loadNote(path: string): Promise<ParsedNote> {
    const content = await fs.readFile(path, 'utf-8');
    
    // Parse only what's needed
    return {
      path,
      content,
      metadata: this.quickParseMetadata(content),
      links: this.quickParseLinks(content),
      headings: this.quickParseHeadings(content)
    };
  }
  
  private quickParseMetadata(content: string): NoteMetadata {
    // Fast regex-based parsing
    const firstLines = content.split('\n').slice(0, 20).join('\n');
    
    if (firstLines.startsWith('---')) {
      const yamlMatch = firstLines.match(/^---\n([\s\S]*?)\n---/);
      if (yamlMatch) {
        try {
          return yaml.parse(yamlMatch[1]);
        } catch {
          return {};
        }
      }
    }
    
    return {};
  }
}
```

### 3. Graph Optimization

```typescript
class OptimizedGraph {
  private adjacencyList: Map<string, Set<string>> = new Map();
  private reverseIndex: Map<string, Set<string>> = new Map();
  private pageRank: Map<string, number> = new Map();
  
  async buildGraph(vault: VaultIndexer): Promise<void> {
    console.log('Building knowledge graph...');
    
    // Build in parallel batches
    const allNotes = await vault.getAllNotePaths();
    const batchSize = 500;
    const workers = 4;
    
    const batches = this.createBatches(allNotes, batchSize);
    const workerPromises: Promise<void>[] = [];
    
    for (let w = 0; w < workers; w++) {
      workerPromises.push(this.processWorker(batches, w, workers, vault));
    }
    
    await Promise.all(workerPromises);
    
    // Calculate PageRank for importance
    await this.calculatePageRank();
  }
  
  private async processWorker(
    batches: string[][],
    workerId: number,
    totalWorkers: number,
    vault: VaultIndexer
  ): Promise<void> {
    for (let i = workerId; i < batches.length; i += totalWorkers) {
      const batch = batches[i];
      
      for (const notePath of batch) {
        const links = await vault.getOutgoingLinks(notePath);
        
        // Update adjacency list
        if (!this.adjacencyList.has(notePath)) {
          this.adjacencyList.set(notePath, new Set());
        }
        
        for (const link of links) {
          this.adjacencyList.get(notePath)!.add(link);
          
          // Update reverse index
          if (!this.reverseIndex.has(link)) {
            this.reverseIndex.set(link, new Set());
          }
          this.reverseIndex.get(link)!.add(notePath);
        }
      }
    }
  }
  
  async getRelatedNotes(
    notePath: string,
    depth: number = 2,
    limit: number = 20
  ): Promise<RelatedNote[]> {
    const visited = new Set<string>();
    const scores = new Map<string, number>();
    
    // BFS with scoring
    const queue: { path: string; depth: number; score: number }[] = [
      { path: notePath, depth: 0, score: 1.0 }
    ];
    
    while (queue.length > 0) {
      const { path, depth: currentDepth, score } = queue.shift()!;
      
      if (visited.has(path) || currentDepth > depth) {
        continue;
      }
      
      visited.add(path);
      
      // Add to scores
      const currentScore = scores.get(path) || 0;
      scores.set(path, currentScore + score);
      
      // Get connected notes
      const outgoing = this.adjacencyList.get(path) || new Set();
      const incoming = this.reverseIndex.get(path) || new Set();
      
      // Score decay based on depth
      const decayFactor = Math.pow(0.5, currentDepth + 1);
      
      for (const connected of [...outgoing, ...incoming]) {
        if (!visited.has(connected)) {
          queue.push({
            path: connected,
            depth: currentDepth + 1,
            score: score * decayFactor
          });
        }
      }
    }
    
    // Sort by score and PageRank
    const results = Array.from(scores.entries())
      .filter(([path]) => path !== notePath)
      .map(([path, score]) => ({
        path,
        score: score * (this.pageRank.get(path) || 0.1),
        type: this.getRelationType(notePath, path)
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
    
    return results;
  }
}
```

## Plugin Compatibility

### 1. Plugin Detection and Adaptation

```typescript
class PluginCompatibilityLayer {
  private detectedPlugins: Map<string, PluginInfo> = new Map();
  private adaptations: Map<string, PluginAdaptation> = new Map();
  
  async detectPlugins(vaultPath: string): Promise<void> {
    const pluginsPath = path.join(vaultPath, '.obsidian', 'plugins');
    
    try {
      const plugins = await fs.readdir(pluginsPath);
      
      for (const pluginId of plugins) {
        const manifestPath = path.join(pluginsPath, pluginId, 'manifest.json');
        
        try {
          const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf-8'));
          
          this.detectedPlugins.set(pluginId, {
            id: pluginId,
            name: manifest.name,
            version: manifest.version,
            description: manifest.description
          });
          
          // Load adaptation if available
          await this.loadAdaptation(pluginId);
        } catch (e) {
          console.warn(`Failed to load plugin manifest: ${pluginId}`);
        }
      }
    } catch (e) {
      console.log('No plugins directory found');
    }
  }
  
  private async loadAdaptation(pluginId: string): Promise<void> {
    // Known plugin adaptations
    const adaptations = {
      'dataview': {
        handleQueries: true,
        preserveCodeBlocks: ['dataview', 'dataviewjs'],
        customParsing: this.parseDataviewQueries.bind(this)
      },
      'templater': {
        handleTemplates: true,
        preserveCodeBlocks: ['templater'],
        beforeWrite: this.processTemplaterCommands.bind(this)
      },
      'obsidian-git': {
        checkGitStatus: true,
        avoidConflicts: true,
        coordination: this.coordinateWithGit.bind(this)
      },
      'calendar': {
        respectDailyNotes: true,
        dateFormat: 'YYYY-MM-DD',
        folderStructure: 'Daily Notes/YYYY/MM'
      }
    };
    
    if (adaptations[pluginId]) {
      this.adaptations.set(pluginId, adaptations[pluginId]);
    }
  }
  
  async processContent(
    content: string,
    action: 'read' | 'write'
  ): Promise<string> {
    let processed = content;
    
    for (const [pluginId, adaptation] of this.adaptations) {
      if (action === 'read' && adaptation.customParsing) {
        processed = await adaptation.customParsing(processed);
      } else if (action === 'write' && adaptation.beforeWrite) {
        processed = await adaptation.beforeWrite(processed);
      }
      
      // Preserve plugin-specific code blocks
      if (adaptation.preserveCodeBlocks) {
        processed = this.preserveCodeBlocks(processed, adaptation.preserveCodeBlocks);
      }
    }
    
    return processed;
  }
  
  private parseDataviewQueries(content: string): string {
    // Parse Dataview queries and add metadata
    const dataviewRegex = /```dataview\n([\s\S]*?)```/g;
    
    return content.replace(dataviewRegex, (match, query) => {
      const parsed = this.parseDataviewQuery(query);
      
      // Add invisible metadata for agent understanding
      return match + `\n<!-- dataview-query: ${JSON.stringify(parsed)} -->`;
    });
  }
}
```

### 2. API Workarounds

```typescript
class ObsidianAPIWorkarounds {
  private apiLimitations = {
    maxFileSize: 10 * 1024 * 1024, // 10MB
    maxBatchSize: 50,
    rateLimitPerMinute: 600,
    unsupportedOperations: ['rename-folder', 'move-multiple']
  };
  
  async writeNote(path: string, content: string): Promise<void> {
    // Check file size
    if (content.length > this.apiLimitations.maxFileSize) {
      // Split into multiple notes
      return this.writeLargeNote(path, content);
    }
    
    // Check rate limit
    await this.enforceRateLimit();
    
    try {
      // Try MCP API first
      await this.mcpClient.createNote(path, content);
    } catch (e) {
      if (e.code === 'UNSUPPORTED_OPERATION') {
        // Fallback to file system
        await this.fileSystemFallback(path, content);
      } else {
        throw e;
      }
    }
  }
  
  private async writeLargeNote(path: string, content: string): Promise<void> {
    const chunks = this.splitIntoChunks(content, this.apiLimitations.maxFileSize * 0.9);
    const baseName = path.replace(/\.md$/, '');
    
    // Write main note with links to chunks
    const mainContent = `# ${baseName}\n\nThis note has been split due to size constraints.\n\n`;
    const chunkLinks = chunks.map((_, i) => `- [[${baseName}-part${i + 1}]]`).join('\n');
    
    await this.writeNote(path, mainContent + chunkLinks);
    
    // Write chunks
    for (let i = 0; i < chunks.length; i++) {
      const chunkPath = `${baseName}-part${i + 1}.md`;
      const chunkContent = `# ${baseName} - Part ${i + 1}\n\n${chunks[i]}`;
      await this.writeNote(chunkPath, chunkContent);
    }
  }
  
  async batchOperation(operations: Operation[]): Promise<BatchResult> {
    const results: OperationResult[] = [];
    const batches = this.createBatches(operations, this.apiLimitations.maxBatchSize);
    
    for (const batch of batches) {
      // Process batch with rate limiting
      const batchResults = await this.processBatchWithRetry(batch);
      results.push(...batchResults);
      
      // Delay between batches
      await this.delay(100);
    }
    
    return {
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      results
    };
  }
}
```

## MCP Server Failure Handling

### 1. Fallback Mechanism

```typescript
class MCPFallbackHandler {
  private mcpHealthy: boolean = true;
  private lastHealthCheck: number = 0;
  private fallbackMode: boolean = false;
  
  async executeWithFallback<T>(
    operation: string,
    mcpOperation: () => Promise<T>,
    fallbackOperation: () => Promise<T>
  ): Promise<T> {
    // Check MCP health
    if (await this.isMCPHealthy()) {
      try {
        const result = await this.withTimeout(mcpOperation(), 5000);
        this.recordSuccess();
        return result;
      } catch (e) {
        this.recordFailure(e);
        
        // Determine if we should fallback
        if (this.shouldFallback(e)) {
          console.warn(`MCP operation failed, using fallback: ${operation}`);
          return await fallbackOperation();
        }
        
        throw e;
      }
    } else {
      // MCP unhealthy, use fallback directly
      return await fallbackOperation();
    }
  }
  
  private async isMCPHealthy(): Promise<boolean> {
    const now = Date.now();
    
    // Cache health check for 30 seconds
    if (now - this.lastHealthCheck < 30000) {
      return this.mcpHealthy;
    }
    
    try {
      const response = await this.mcpClient.health();
      this.mcpHealthy = response.status === 'ok';
      this.lastHealthCheck = now;
      
      if (this.mcpHealthy && this.fallbackMode) {
        console.log('MCP server recovered, exiting fallback mode');
        this.fallbackMode = false;
      }
      
      return this.mcpHealthy;
    } catch (e) {
      this.mcpHealthy = false;
      this.lastHealthCheck = now;
      return false;
    }
  }
  
  private shouldFallback(error: any): boolean {
    const fallbackErrors = [
      'ECONNREFUSED',
      'ETIMEDOUT',
      'ENOTFOUND',
      'API_RATE_LIMIT',
      'SERVER_ERROR'
    ];
    
    return fallbackErrors.includes(error.code) || 
           error.statusCode >= 500;
  }
}
```

### 2. Queue and Retry System

```typescript
class OperationQueue {
  private queue: PriorityQueue<QueuedOperation> = new PriorityQueue();
  private processing: boolean = false;
  private retryPolicy: RetryPolicy;
  
  async enqueue(
    operation: Operation,
    priority: Priority = 'normal'
  ): Promise<OperationResult> {
    const queuedOp: QueuedOperation = {
      id: generateId(),
      operation,
      priority,
      attempts: 0,
      enqueueTime: Date.now(),
      deferred: new Deferred<OperationResult>()
    };
    
    this.queue.push(queuedOp);
    
    // Start processing if not already running
    if (!this.processing) {
      this.processQueue();
    }
    
    return queuedOp.deferred.promise;
  }
  
  private async processQueue(): Promise<void> {
    this.processing = true;
    
    while (!this.queue.isEmpty()) {
      const op = this.queue.pop();
      if (!op) break;
      
      try {
        const result = await this.executeOperation(op);
        op.deferred.resolve(result);
      } catch (e) {
        if (this.shouldRetry(op, e)) {
          op.attempts++;
          op.lastError = e;
          
          // Re-queue with backoff
          const backoffMs = this.calculateBackoff(op.attempts);
          setTimeout(() => {
            this.queue.push(op);
            if (!this.processing) {
              this.processQueue();
            }
          }, backoffMs);
        } else {
          op.deferred.reject(e);
        }
      }
    }
    
    this.processing = false;
  }
  
  private shouldRetry(op: QueuedOperation, error: any): boolean {
    if (op.attempts >= this.retryPolicy.maxAttempts) {
      return false;
    }
    
    const retryableErrors = ['ECONNREFUSED', 'ETIMEDOUT', 'API_RATE_LIMIT'];
    return retryableErrors.includes(error.code);
  }
  
  private calculateBackoff(attempts: number): number {
    // Exponential backoff with jitter
    const baseDelay = Math.min(1000 * Math.pow(2, attempts), 30000);
    const jitter = Math.random() * 0.3 * baseDelay;
    return baseDelay + jitter;
  }
}
```

### 3. Graceful Degradation

```typescript
class GracefulDegradation {
  private capabilities: Set<string> = new Set();
  private degradedMode: boolean = false;
  
  async checkCapabilities(): Promise<void> {
    this.capabilities.clear();
    
    // Test each capability
    const tests = [
      { name: 'mcp_api', test: () => this.testMCPAPI() },
      { name: 'obsidian_search', test: () => this.testSearch() },
      { name: 'real_time_sync', test: () => this.testRealTimeSync() },
      { name: 'plugin_api', test: () => this.testPluginAPI() },
      { name: 'graph_queries', test: () => this.testGraphQueries() }
    ];
    
    for (const { name, test } of tests) {
      try {
        await test();
        this.capabilities.add(name);
      } catch (e) {
        console.warn(`Capability unavailable: ${name}`);
      }
    }
    
    // Determine if we're in degraded mode
    this.degradedMode = this.capabilities.size < tests.length;
    
    if (this.degradedMode) {
      await this.notifyDegradedMode();
    }
  }
  
  async performOperation(
    operation: string,
    params: any
  ): Promise<OperationResult> {
    // Route to appropriate implementation based on capabilities
    const strategies = this.getStrategies(operation);
    
    for (const strategy of strategies) {
      if (this.canExecuteStrategy(strategy)) {
        try {
          return await strategy.execute(params);
        } catch (e) {
          console.warn(`Strategy failed: ${strategy.name}`, e);
          continue;
        }
      }
    }
    
    throw new Error(`No available strategy for operation: ${operation}`);
  }
  
  private getStrategies(operation: string): Strategy[] {
    const strategyMap = {
      'search': [
        { name: 'mcp_search', requires: ['mcp_api'], execute: this.mcpSearch },
        { name: 'indexed_search', requires: [], execute: this.indexedSearch },
        { name: 'file_grep', requires: [], execute: this.fileGrep }
      ],
      'create_note': [
        { name: 'mcp_create', requires: ['mcp_api'], execute: this.mcpCreate },
        { name: 'fs_create', requires: [], execute: this.fsCreate }
      ],
      'get_graph': [
        { name: 'graph_api', requires: ['graph_queries'], execute: this.graphAPI },
        { name: 'cached_graph', requires: [], execute: this.cachedGraph },
        { name: 'rebuild_graph', requires: [], execute: this.rebuildGraph }
      ]
    };
    
    return strategyMap[operation] || [];
  }
}
```

## Performance Monitoring

### 1. Edge Case Detection

```typescript
class EdgeCaseMonitor {
  private metrics: Map<string, EdgeCaseMetric> = new Map();
  private alerts: Alert[] = [];
  
  async monitorOperation(
    operation: string,
    context: OperationContext
  ): Promise<void> {
    const startTime = performance.now();
    const startMemory = process.memoryUsage();
    
    try {
      // Execute operation
      await context.execute();
      
      // Record success metrics
      this.recordMetric(operation, {
        duration: performance.now() - startTime,
        memoryDelta: process.memoryUsage().heapUsed - startMemory.heapUsed,
        success: true,
        context: context.type
      });
    } catch (e) {
      // Record failure metrics
      this.recordMetric(operation, {
        duration: performance.now() - startTime,
        memoryDelta: process.memoryUsage().heapUsed - startMemory.heapUsed,
        success: false,
        error: e.message,
        context: context.type
      });
      
      // Check if this is an edge case
      if (this.isEdgeCase(operation, e)) {
        await this.handleEdgeCase(operation, e, context);
      }
      
      throw e;
    }
  }
  
  private isEdgeCase(operation: string, error: any): boolean {
    const edgeCasePatterns = [
      /concurrent modification/i,
      /file locked/i,
      /vault size exceeded/i,
      /plugin conflict/i,
      /mcp timeout/i
    ];
    
    return edgeCasePatterns.some(pattern => 
      pattern.test(error.message)
    );
  }
}
```

## Testing Strategies

### 1. Chaos Testing

```typescript
class ChaosTest {
  async runChaosTests(): Promise<TestResults> {
    const scenarios = [
      this.testConcurrentEdits(),
      this.testLargeVaultOperations(),
      this.testMCPFailures(),
      this.testPluginConflicts(),
      this.testRapidFileChanges()
    ];
    
    const results = await Promise.all(scenarios);
    
    return {
      passed: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      details: results
    };
  }
  
  private async testConcurrentEdits(): Promise<TestResult> {
    // Simulate user editing while agent writes
    const testFile = 'test-concurrent.md';
    
    // Start agent write
    const agentWrite = this.agentWrite(testFile, 'Agent content');
    
    // Simulate user edit after 100ms
    setTimeout(() => {
      this.simulateObsidianEdit(testFile, 'User content');
    }, 100);
    
    try {
      await agentWrite;
      
      // Verify conflict was handled
      const finalContent = await this.readFile(testFile);
      return {
        success: finalContent.includes('Agent content') || 
                 finalContent.includes('User content'),
        scenario: 'concurrent_edits',
        details: 'Conflict handled gracefully'
      };
    } catch (e) {
      return {
        success: false,
        scenario: 'concurrent_edits',
        error: e.message
      };
    }
  }
}
```

## Conclusion

This comprehensive edge case handling ensures ClaudeProjects2 can:

1. **Handle Conflicts**: Gracefully resolve concurrent edits
2. **Scale Performance**: Work with vaults of any size
3. **Maintain Compatibility**: Adapt to popular plugins
4. **Ensure Reliability**: Continue operating when MCP fails
5. **Provide Transparency**: Monitor and report edge cases

The design prioritizes user data integrity while maintaining the 10x productivity promise even under challenging conditions.