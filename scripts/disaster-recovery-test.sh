#!/bin/bash

# Sleek Multi-Region Disaster Recovery Test Script
# Tests infrastructure resilience by simulating various failure scenarios

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGION=""
DURATION="30m"
TEST_TYPE="all"
DRY_RUN=false
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Sleek Multi-Region Disaster Recovery Test Script

USAGE:
    $0 --region REGION [OPTIONS]

REQUIRED:
    --region REGION     Target region for disaster simulation
                       (singapore, hongkong, australia, uk)

OPTIONS:
    --duration TIME     Duration of the test (default: 30m)
                       Examples: 5m, 1h, 30s
    --test-type TYPE    Type of disaster test (default: all)
                       Options: instance, database, network, all
    --dry-run          Show what would be done without executing
    --help             Show this help message

EXAMPLES:
    # Simulate complete region failure for 30 minutes
    $0 --region singapore --duration 30m

    # Test database failover only
    $0 --region australia --test-type database --duration 15m

    # Dry run to see planned actions
    $0 --region uk --dry-run

DISASTER SCENARIOS:
    instance    - Stop EC2 instances in Auto Scaling Group
    database    - Simulate RDS connectivity issues
    network     - Block load balancer traffic
    all         - Simulate complete regional failure

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --region)
                REGION="$2"
                shift 2
                ;;
            --duration)
                DURATION="$2"
                shift 2
                ;;
            --test-type)
                TEST_TYPE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$REGION" ]]; then
        error "Region is required. Use --region to specify."
        show_help
        exit 1
    fi

    # Validate region
    case $REGION in
        singapore|hongkong|australia|uk)
            ;;
        *)
            error "Invalid region: $REGION. Must be one of: singapore, hongkong, australia, uk"
            exit 1
            ;;
    esac

    # Validate test type
    case $TEST_TYPE in
        instance|database|network|all)
            ;;
        *)
            error "Invalid test type: $TEST_TYPE. Must be one of: instance, database, network, all"
            exit 1
            ;;
    esac
}

# Convert duration to seconds for sleep
duration_to_seconds() {
    local duration=$1
    case $duration in
        *s) echo "${duration%s}" ;;
        *m) echo "$((${duration%m} * 60))" ;;
        *h) echo "$((${duration%h} * 3600))" ;;
        *) echo "1800" ;; # Default 30 minutes
    esac
}

# Get region details
get_region_details() {
    local region=$1
    case $region in
        singapore)
            AWS_REGION="ap-southeast-1"
            ;;
        hongkong)
            AWS_REGION="ap-northeast-1"
            ;;
        australia)
            AWS_REGION="ap-southeast-2"
            ;;
        uk)
            AWS_REGION="eu-west-2"
            ;;
    esac
}

# Check if resources exist
check_resources() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    if [[ ! -d "$env_dir" ]]; then
        error "Region directory not found: $env_dir"
        return 1
    fi

    if [[ ! -f "$env_dir/terraform.tfstate" ]]; then
        error "No terraform state found for $region. Deploy infrastructure first."
        return 1
    fi

    # Check if resources are actually deployed
    cd "$env_dir"
    local resource_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.child_modules | length' 2>/dev/null || echo "0")
    if [[ "$resource_count" -eq 0 ]]; then
        error "No resources found in $region terraform state"
        return 1
    fi

    success "Found infrastructure modules in $region"
    return 0
}

# Get Auto Scaling Group name
get_asg_name() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    cd "$env_dir"
    terraform show -json | jq -r '.values.root_module.child_modules[].resources[] | select(.type=="aws_autoscaling_group") | .values.name' 2>/dev/null || echo ""
}

# Get RDS instance identifier
get_rds_identifier() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    cd "$env_dir"
    terraform show -json | jq -r '.values.root_module.child_modules[].resources[] | select(.type=="aws_db_instance") | .values.identifier' 2>/dev/null || echo ""
}

# Get Load Balancer ARN
get_lb_arn() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    cd "$env_dir"
    terraform show -json | jq -r '.values.root_module.child_modules[].resources[] | select(.type=="aws_lb") | .values.arn' 2>/dev/null || echo ""
}

# Simulate instance failure
simulate_instance_failure() {
    local region=$1
    local aws_region=$2
    
    log "Simulating EC2 instance failure in $region..."
    
    local asg_name=$(get_asg_name "$region")
    if [[ -z "$asg_name" ]]; then
        error "Could not find Auto Scaling Group for $region"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would set ASG $asg_name desired capacity to 0"
        return 0
    fi

    # Set desired capacity to 0 to simulate instance failure
    aws autoscaling update-auto-scaling-group \
        --region "$aws_region" \
        --auto-scaling-group-name "$asg_name" \
        --desired-capacity 0 \
        --min-size 0

    success "Stopped instances in Auto Scaling Group: $asg_name"
}

# Restore instance capacity
restore_instance_capacity() {
    local region=$1
    local aws_region=$2
    
    log "Restoring EC2 instance capacity in $region..."
    
    local asg_name=$(get_asg_name "$region")
    if [[ -z "$asg_name" ]]; then
        error "Could not find Auto Scaling Group for $region"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would restore ASG $asg_name to desired capacity 2"
        return 0
    fi

    # Restore normal capacity
    aws autoscaling update-auto-scaling-group \
        --region "$aws_region" \
        --auto-scaling-group-name "$asg_name" \
        --desired-capacity 2 \
        --min-size 2

    success "Restored instances in Auto Scaling Group: $asg_name"
    
    # Wait for instances to be healthy
    log "Waiting for instances to become healthy..."
    aws autoscaling wait group-in-service \
        --region "$aws_region" \
        --auto-scaling-group-names "$asg_name"
    
    success "Instances are now healthy"
}

# Simulate database failure
simulate_database_failure() {
    local region=$1
    local aws_region=$2
    
    log "Simulating database connectivity issues in $region..."
    
    local rds_identifier=$(get_rds_identifier "$region")
    if [[ -z "$rds_identifier" ]]; then
        error "Could not find RDS instance for $region"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would create security group rule to block database access"
        return 0
    fi

    # Note: We don't actually stop the RDS instance as that takes too long
    # Instead, we could modify security groups, but that's complex to restore
    warning "Database failure simulation not implemented (would take too long to restore)"
    warning "Consider implementing security group rule changes for faster testing"
}

# Simulate network failure
simulate_network_failure() {
    local region=$1
    local aws_region=$2
    
    log "Simulating network failure in $region..."
    
    local lb_arn=$(get_lb_arn "$region")
    if [[ -z "$lb_arn" ]]; then
        error "Could not find Load Balancer for $region"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would modify load balancer listener to return 503 errors"
        return 0
    fi

    warning "Network failure simulation not implemented"
    warning "Consider implementing load balancer listener rule changes"
}

# Monitor other regions during test
monitor_failover() {
    local failed_region=$1
    local duration_seconds=$2
    
    log "Monitoring other regions during $failed_region failure..."
    log "Test duration: ${DURATION} (${duration_seconds} seconds)"
    
    # Check Prometheus is accessible
    if ! curl -s http://localhost:9090/api/v1/query?query=up >/dev/null; then
        warning "Prometheus not accessible. Cannot monitor failover automatically."
        return 1
    fi

    local start_time=$(date +%s)
    local end_time=$((start_time + duration_seconds))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local remaining=$((end_time - current_time))
        
        log "Test progress: ${elapsed}s elapsed, ${remaining}s remaining"
        
        # Check health of all regions
        local healthy_regions=$(curl -s 'http://localhost:9090/api/v1/query?query=probe_success{job=~"blackbox-http-.*"}' | \
            jq -r '.data.result[] | select(.value[1] == "1") | .metric.region' | \
            sort -u | wc -l)
            
        log "Healthy regions: $healthy_regions/4"
        
        # Sleep for 30 seconds before next check
        sleep 30
    done
    
    success "Monitoring completed"
}

# Run disaster recovery test
run_test() {
    local region=$1
    
    log "Starting disaster recovery test for $region"
    log "Test type: $TEST_TYPE"
    log "Duration: $DURATION"
    
    get_region_details "$region"
    
    if ! check_resources "$region"; then
        error "Resource check failed for $region"
        exit 1
    fi

    local duration_seconds=$(duration_to_seconds "$DURATION")
    
    # Record test start
    log "=== DISASTER RECOVERY TEST STARTED ==="
    log "Target Region: $region ($AWS_REGION)"
    log "Test Type: $TEST_TYPE"
    log "Duration: $DURATION ($duration_seconds seconds)"
    log "Dry Run: $DRY_RUN"
    
    # Execute failure simulation based on test type
    case $TEST_TYPE in
        instance|all)
            simulate_instance_failure "$region" "$AWS_REGION"
            ;;
    esac
    
    case $TEST_TYPE in
        database|all)
            simulate_database_failure "$region" "$AWS_REGION"
            ;;
    esac
    
    case $TEST_TYPE in
        network|all)
            simulate_network_failure "$region" "$AWS_REGION"
            ;;
    esac
    
    if [[ "$DRY_RUN" == "true" ]]; then
        success "Dry run completed. No actual changes made."
        exit 0
    fi
    
    # Monitor the failure
    monitor_failover "$region" "$duration_seconds"
    
    # Restore services
    log "=== RESTORING SERVICES ==="
    
    case $TEST_TYPE in
        instance|all)
            restore_instance_capacity "$region" "$AWS_REGION"
            ;;
    esac
    
    success "=== DISASTER RECOVERY TEST COMPLETED ==="
    log "Check Grafana dashboard to verify all regions are healthy again"
    log "Dashboard: http://localhost:3000/d/sleek-clean-overview/sleek-multi-region-clean-overview"
}

# Main function
main() {
    parse_args "$@"
    
    # Check prerequisites
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        error "jq is not installed"
        exit 1
    fi
    
    # Run the test
    run_test "$REGION"
}

# Execute main function with all arguments
main "$@"