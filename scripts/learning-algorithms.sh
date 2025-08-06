#!/bin/bash
# Learning Algorithms for Agent Intelligence
# Sprint 9, Day 6: Machine learning for team optimization

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
LEARNING_DB="$PROJECT_ROOT/.cpdm/intelligence/learning.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Initialize learning database
init_learning_db() {
    mkdir -p "$(dirname "$LEARNING_DB")"
    
    sqlite3 "$LEARNING_DB" <<'SQL'
-- Learning models table
CREATE TABLE IF NOT EXISTS learning_models (
    id TEXT PRIMARY KEY,
    model_name TEXT NOT NULL,
    model_type TEXT,  -- regression, classification, clustering
    parameters TEXT,   -- JSON
    training_data TEXT,
    accuracy REAL,
    last_trained TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Feature vectors for agents
CREATE TABLE IF NOT EXISTS agent_features (
    agent_name TEXT PRIMARY KEY,
    avg_response_time REAL,
    success_rate REAL,
    error_rate REAL,
    complexity_score REAL,
    collaboration_score REAL,
    feature_vector TEXT,  -- JSON array
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Task similarity matrix
CREATE TABLE IF NOT EXISTS task_similarity (
    task1_id TEXT,
    task2_id TEXT,
    similarity_score REAL,
    shared_domains TEXT,
    shared_skills TEXT,
    PRIMARY KEY (task1_id, task2_id)
);

-- Team effectiveness scores
CREATE TABLE IF NOT EXISTS team_effectiveness (
    team_hash TEXT PRIMARY KEY,
    team_members TEXT,
    task_types TEXT,
    effectiveness_score REAL,
    sample_count INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Learning history
CREATE TABLE IF NOT EXISTS learning_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    algorithm TEXT,
    input_data TEXT,
    output_prediction TEXT,
    actual_outcome TEXT,
    accuracy REAL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_features_agent ON agent_features(agent_name);
CREATE INDEX IF NOT EXISTS idx_similarity_score ON task_similarity(similarity_score);
CREATE INDEX IF NOT EXISTS idx_effectiveness ON team_effectiveness(effectiveness_score);
SQL
    
    echo -e "${GREEN}Learning database initialized${NC}"
}

# Extract features from agent performance
extract_agent_features() {
    echo -e "${BLUE}Extracting agent features...${NC}"
    
    # Calculate features for each agent
    while IFS='|' read -r agent avg_time success error; do
        # Calculate additional features
        local complexity=$(echo "scale=2; $avg_time / 1000" | bc)
        local collaboration=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(DISTINCT p2.agent_id) 
             FROM performance_metrics p1 
             JOIN performance_metrics p2 ON p1.context_id = p2.context_id 
             WHERE p1.agent_id = '$agent' AND p2.agent_id != '$agent';")
        
        # Create feature vector
        local feature_vector="[$avg_time, $success, $error, $complexity, $collaboration]"
        
        # Store features
        sqlite3 "$LEARNING_DB" <<FEATURE
INSERT OR REPLACE INTO agent_features 
(agent_name, avg_response_time, success_rate, error_rate, complexity_score, collaboration_score, feature_vector)
VALUES 
('$agent', $avg_time, $success, $error, $complexity, $collaboration, '$feature_vector');
FEATURE
    done < <(sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    agent_id,
    COALESCE(AVG(duration_ms), 0) as avg_time,
    ROUND(100.0 * SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) as success_rate,
    ROUND(100.0 * SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) as error_rate
FROM performance_metrics
WHERE agent_id IS NOT NULL
GROUP BY agent_id;
SQL
    )
    
    local feature_count=$(sqlite3 "$LEARNING_DB" "SELECT COUNT(*) FROM agent_features;")
    echo -e "${GREEN}Extracted features for $feature_count agents${NC}"
}

# Calculate task similarity
calculate_task_similarity() {
    local task1="$1"
    local task2="$2"
    
    # Get task features from context
    local features1=$(sqlite3 "$CONTEXT_DB" \
        "SELECT state FROM contexts WHERE task_id='$task1' LIMIT 1;")
    local features2=$(sqlite3 "$CONTEXT_DB" \
        "SELECT state FROM contexts WHERE task_id='$task2' LIMIT 1;")
    
    # Extract domains and skills
    local domains1=$(echo "$features1" | jq -r '.domains[]?' 2>/dev/null | sort | uniq)
    local domains2=$(echo "$features2" | jq -r '.domains[]?' 2>/dev/null | sort | uniq)
    
    # Calculate Jaccard similarity
    local intersection=$(comm -12 <(echo "$domains1") <(echo "$domains2") | wc -l)
    local union=$(echo -e "$domains1\n$domains2" | sort | uniq | wc -l)
    
    local similarity=0
    if [ "$union" -gt 0 ]; then
        similarity=$(echo "scale=3; $intersection / $union" | bc)
    fi
    
    echo "$similarity"
}

# K-means clustering for agent grouping
kmeans_clustering() {
    local k="${1:-3}"  # Number of clusters
    
    echo -e "${BLUE}Performing K-means clustering (k=$k)...${NC}"
    
    # Simple k-means implementation
    # Note: In production, use proper ML library
    
    # Get agent features
    local agents=()
    local features=()
    
    while IFS='|' read -r agent feature_vector; do
        agents+=("$agent")
        features+=("$feature_vector")
    done < <(sqlite3 "$LEARNING_DB" "SELECT agent_name, feature_vector FROM agent_features;")
    
    # Initialize centroids randomly
    local centroids=()
    for ((i=0; i<k; i++)); do
        centroids+=("${features[$((RANDOM % ${#features[@]})]}")
    done
    
    # Iterate clustering (simplified)
    for iteration in {1..10}; do
        # Assign agents to clusters
        local clusters=()
        for ((i=0; i<${#agents[@]}; i++)); do
            local min_dist=999999
            local cluster=0
            
            for ((c=0; c<k; c++)); do
                # Calculate distance (simplified Euclidean)
                local dist=$(calculate_distance "${features[$i]}" "${centroids[$c]}")
                if (( $(echo "$dist < $min_dist" | bc -l) )); then
                    min_dist=$dist
                    cluster=$c
                fi
            done
            
            clusters[$i]=$cluster
        done
        
        # Update centroids
        for ((c=0; c<k; c++)); do
            # Calculate mean of cluster members
            # (Simplified - would need proper vector math)
            centroids[$c]="[0, 0, 0, 0, 0]"
        done
    done
    
    # Output clusters
    echo -e "${GREEN}Agent Clusters:${NC}"
    for ((i=0; i<${#agents[@]}; i++)); do
        echo "  ${agents[$i]} -> Cluster ${clusters[$i]}"
    done
}

# Calculate distance between feature vectors
calculate_distance() {
    local vec1="$1"
    local vec2="$2"
    
    # Parse vectors
    local arr1=($(echo "$vec1" | tr -d '[]' | tr ',' ' '))
    local arr2=($(echo "$vec2" | tr -d '[]' | tr ',' ' '))
    
    # Euclidean distance
    local sum=0
    for ((i=0; i<${#arr1[@]}; i++)); do
        local diff=$(echo "${arr1[$i]} - ${arr2[$i]}" | bc)
        local squared=$(echo "$diff * $diff" | bc)
        sum=$(echo "$sum + $squared" | bc)
    done
    
    echo "scale=3; sqrt($sum)" | bc
}

# Predict optimal team using regression
predict_optimal_team() {
    local task_description="$1"
    
    echo -e "${BLUE}Predicting optimal team for: $task_description${NC}"
    
    # Extract task features
    local task_analysis=$(./scripts/agent-organizer.sh analyze "$task_description")
    local domains=$(echo "$task_analysis" | jq -r '.domains[]' | tr '\n' ',' | sed 's/,$//')
    
    # Find similar past tasks
    echo -e "${YELLOW}Finding similar tasks...${NC}"
    
    # Get successful teams from similar tasks
    local similar_teams=$(sqlite3 -separator ',' "$LEARNING_DB" <<SQL
SELECT DISTINCT team_members, effectiveness_score
FROM team_effectiveness
WHERE task_types LIKE '%${domains%,*}%'
  AND effectiveness_score > 0.8
ORDER BY effectiveness_score DESC
LIMIT 5;
SQL
    )
    
    if [ -n "$similar_teams" ]; then
        echo -e "${GREEN}Recommended teams based on similar tasks:${NC}"
        echo "$similar_teams" | while IFS=',' read -r team score; do
            echo "  Team: $team (Score: $score)"
        done
    else
        echo -e "${YELLOW}No similar tasks found, using feature-based prediction${NC}"
        
        # Use agent features to compose team
        local recommended_agents=$(sqlite3 -separator ',' "$LEARNING_DB" <<SQL
SELECT agent_name
FROM agent_features
WHERE success_rate > 90
  AND avg_response_time < 3000
ORDER BY success_rate DESC, avg_response_time ASC
LIMIT 3;
SQL
        )
        
        echo -e "${GREEN}Feature-based team recommendation:${NC}"
        echo "  $recommended_agents"
    fi
}

# Train team effectiveness model
train_effectiveness_model() {
    echo -e "${BLUE}Training team effectiveness model...${NC}"
    
    # Collect training data from performance history
    while IFS='|' read -r context_id agents success_rate avg_time; do
        # Calculate effectiveness score
        local effectiveness=$(echo "scale=3; ($success_rate * 0.7) + ((10000 - $avg_time) / 10000 * 0.3)" | bc)
        
        # Hash team for uniqueness
        local team_hash=$(echo "$agents" | md5sum | cut -c1-16)
        
        # Store effectiveness
        sqlite3 "$LEARNING_DB" <<EFFECT
INSERT OR REPLACE INTO team_effectiveness 
(team_hash, team_members, effectiveness_score, sample_count)
VALUES 
('$team_hash', '$agents', $effectiveness, 1)
ON CONFLICT(team_hash) DO UPDATE SET
  effectiveness_score = (effectiveness_score * sample_count + $effectiveness) / (sample_count + 1),
  sample_count = sample_count + 1,
  last_updated = CURRENT_TIMESTAMP;
EFFECT
    done < <(sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    c.id,
    GROUP_CONCAT(DISTINCT p.agent_id) as agents,
    ROUND(100.0 * SUM(CASE WHEN p.success = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate,
    AVG(p.duration_ms) as avg_time
FROM contexts c
JOIN performance_metrics p ON c.id = p.context_id
WHERE p.agent_id IS NOT NULL
GROUP BY c.id
HAVING COUNT(DISTINCT p.agent_id) > 1;
SQL
    )
    
    local model_count=$(sqlite3 "$LEARNING_DB" "SELECT COUNT(*) FROM team_effectiveness;")
    echo -e "${GREEN}Trained model with $model_count team combinations${NC}"
}

# Reinforcement learning update
reinforcement_update() {
    local context_id="$1"
    local reward="$2"  # 1 for success, -1 for failure
    
    echo -e "${BLUE}Applying reinforcement learning update...${NC}"
    
    # Get team from context
    local team=$(sqlite3 "$CONTEXT_DB" \
        "SELECT GROUP_CONCAT(DISTINCT agent_id) FROM performance_metrics 
         WHERE context_id='$context_id';")
    
    if [ -n "$team" ]; then
        local team_hash=$(echo "$team" | md5sum | cut -c1-16)
        
        # Update effectiveness with learning rate
        local learning_rate=0.1
        sqlite3 "$LEARNING_DB" <<SQL
UPDATE team_effectiveness 
SET effectiveness_score = effectiveness_score + ($learning_rate * $reward),
    last_updated = CURRENT_TIMESTAMP
WHERE team_hash = '$team_hash';
SQL
        
        echo -e "${GREEN}Updated team effectiveness with reward: $reward${NC}"
    fi
}

# Generate learning report
generate_learning_report() {
    echo -e "${MAGENTA}=== LEARNING SYSTEM REPORT ===${NC}\n"
    
    # Model statistics
    echo -e "${BLUE}Model Statistics:${NC}"
    sqlite3 -column -header "$LEARNING_DB" <<SQL
SELECT 
    'Agent Features' as Model, 
    COUNT(*) as Records,
    ROUND(AVG(success_rate), 2) as 'Avg Success'
FROM agent_features
UNION ALL
SELECT 
    'Team Effectiveness',
    COUNT(*),
    ROUND(AVG(effectiveness_score), 3)
FROM team_effectiveness;
SQL
    
    # Top performing teams
    echo -e "\n${BLUE}Top Performing Teams:${NC}"
    sqlite3 -column -header "$LEARNING_DB" <<SQL
SELECT 
    substr(team_members, 1, 50) as Team,
    ROUND(effectiveness_score, 3) as Score,
    sample_count as Samples
FROM team_effectiveness
ORDER BY effectiveness_score DESC
LIMIT 5;
SQL
    
    # Agent clusters
    echo -e "\n${BLUE}Agent Feature Summary:${NC}"
    sqlite3 -column -header "$LEARNING_DB" <<SQL
SELECT 
    agent_name as Agent,
    ROUND(success_rate, 1) || '%' as Success,
    ROUND(avg_response_time, 0) || 'ms' as 'Avg Time',
    ROUND(collaboration_score, 1) as Collaboration
FROM agent_features
ORDER BY success_rate DESC
LIMIT 10;
SQL
    
    # Learning accuracy
    echo -e "\n${BLUE}Learning Accuracy:${NC}"
    sqlite3 -column -header "$LEARNING_DB" <<SQL
SELECT 
    algorithm as Algorithm,
    COUNT(*) as Predictions,
    ROUND(AVG(accuracy), 3) as 'Avg Accuracy'
FROM learning_history
GROUP BY algorithm
ORDER BY AVG(accuracy) DESC;
SQL
}

# Main command handler
case "${1:-help}" in
    init)
        init_learning_db
        ;;
    extract)
        extract_agent_features
        ;;
    train)
        train_effectiveness_model
        ;;
    predict)
        predict_optimal_team "$2"
        ;;
    cluster)
        kmeans_clustering "${2:-3}"
        ;;
    reinforce)
        reinforcement_update "$2" "$3"
        ;;
    similarity)
        calculate_task_similarity "$2" "$3"
        ;;
    report)
        generate_learning_report
        ;;
    help|*)
        echo "Learning Algorithms for Agent Intelligence"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  init                      - Initialize learning database"
        echo "  extract                   - Extract agent features"
        echo "  train                     - Train effectiveness model"
        echo "  predict <task>            - Predict optimal team"
        echo "  cluster [k]               - K-means clustering of agents"
        echo "  reinforce <ctx> <reward>  - Apply reinforcement learning"
        echo "  similarity <t1> <t2>      - Calculate task similarity"
        echo "  report                    - Generate learning report"
        ;;
esac