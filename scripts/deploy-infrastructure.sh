#!/bin/bash

# Sleek Multi-Region Infrastructure Deployment Script
# Deploys infrastructure across Singapore, Hong Kong, Australia, and UK regions

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGIONS=("singapore" "hongkong" "australia" "uk")
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

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    log "Initializing Terraform for ${region}..."
    cd "${env_dir}"
    
    if terraform init; then
        success "Terraform initialized for ${region}"
    else
        error "Failed to initialize Terraform for ${region}"
        return 1
    fi
}

# Plan Terraform deployment
plan_terraform() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    log "Planning Terraform deployment for ${region}..."
    cd "${env_dir}"
    
    if terraform plan -out="terraform.tfplan"; then
        success "Terraform plan created for ${region}"
    else
        error "Failed to create Terraform plan for ${region}"
        return 1
    fi
}

# Apply Terraform deployment
apply_terraform() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    log "Applying Terraform deployment for ${region}..."
    cd "${env_dir}"
    
    if terraform apply "terraform.tfplan"; then
        success "Terraform applied successfully for ${region}"
    else
        error "Failed to apply Terraform for ${region}"
        return 1
    fi
}

# Get deployment outputs
get_outputs() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    log "Getting outputs for ${region}..."
    cd "${env_dir}"
    
    terraform output -json > "${PROJECT_ROOT}/outputs_${region}.json"
    
    # Extract key outputs
    local lb_dns=$(terraform output -raw load_balancer_dns_name 2>/dev/null || echo "N/A")
    local vpc_id=$(terraform output -raw vpc_id 2>/dev/null || echo "N/A")
    
    echo "Region: ${region}"
    echo "  Load Balancer DNS: ${lb_dns}"
    echo "  VPC ID: ${vpc_id}"
    echo ""
}

# Deploy to single region
deploy_region() {
    local region=$1
    
    log "Starting deployment for ${region} region..."
    
    if init_terraform "${region}" && plan_terraform "${region}" && apply_terraform "${region}"; then
        success "Successfully deployed infrastructure in ${region}"
        get_outputs "${region}"
        return 0
    else
        error "Failed to deploy infrastructure in ${region}"
        return 1
    fi
}

# Deploy to all regions
deploy_all_regions() {
    local failed_regions=()
    
    log "Starting multi-region deployment..."
    
    for region in "${REGIONS[@]}"; do
        if deploy_region "${region}"; then
            success "Deployment completed for ${region}"
        else
            error "Deployment failed for ${region}"
            failed_regions+=("${region}")
        fi
        echo ""
    done
    
    # Summary
    echo "========================================="
    echo "DEPLOYMENT SUMMARY"
    echo "========================================="
    
    local successful_regions=()
    for region in "${REGIONS[@]}"; do
        if [[ ! " ${failed_regions[@]} " =~ " ${region} " ]]; then
            successful_regions+=("${region}")
        fi
    done
    
    echo "Successful deployments: ${#successful_regions[@]}"
    for region in "${successful_regions[@]}"; do
        echo "  ✓ ${region}"
    done
    
    if [ ${#failed_regions[@]} -gt 0 ]; then
        echo ""
        echo "Failed deployments: ${#failed_regions[@]}"
        for region in "${failed_regions[@]}"; do
            echo "  ✗ ${region}"
        done
        return 1
    fi
    
    return 0
}

# Destroy infrastructure
destroy_region() {
    local region=$1
    local env_dir="${TERRAFORM_DIR}/environments/${region}"
    
    warning "Destroying infrastructure in ${region}..."
    cd "${env_dir}"
    
    if terraform destroy -auto-approve; then
        success "Infrastructure destroyed in ${region}"
    else
        error "Failed to destroy infrastructure in ${region}"
        return 1
    fi
}

destroy_all_regions() {
    log "Starting infrastructure destruction across all regions..."
    
    for region in "${REGIONS[@]}"; do
        destroy_region "${region}"
    done
}

# Validate deployment
validate_deployment() {
    log "Validating deployment across all regions..."
    
    # Check if Python script exists
    local health_check_script="${PROJECT_ROOT}/scripts/health-check-synthetic.py"
    if [ -f "${health_check_script}" ]; then
        log "Running health checks..."
        python3 "${health_check_script}" --verbose
    else
        warning "Health check script not found, skipping validation"
    fi
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring stack..."
    
    cd "${PROJECT_ROOT}"
    
    # Start monitoring stack with Docker Compose
    if command -v docker-compose &> /dev/null; then
        log "Starting monitoring services..."
        docker-compose up -d
        
        # Wait for services to start
        sleep 30
        
        # Check service status
        if docker-compose ps | grep -q "Up"; then
            success "Monitoring stack started successfully"
            echo ""
            echo "Access URLs:"
            echo "  Grafana: http://localhost:3000 (admin/sleek-monitor-2024)"
            echo "  Prometheus: http://localhost:9090"
            echo "  AlertManager: http://localhost:9093"
        else
            error "Some monitoring services failed to start"
        fi
    else
        warning "Docker Compose not found, skipping monitoring setup"
    fi
}

# Main function
main() {
    local action=${1:-"deploy"}
    
    case $action in
        "deploy")
            check_prerequisites
            deploy_all_regions
            if [ $? -eq 0 ]; then
                setup_monitoring
                validate_deployment
                success "Multi-region deployment completed successfully!"
            else
                error "Multi-region deployment completed with errors"
                exit 1
            fi
            ;;
        "destroy")
            warning "This will destroy ALL infrastructure across ALL regions!"
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                destroy_all_regions
            else
                log "Destruction cancelled"
            fi
            ;;
        "validate")
            validate_deployment
            ;;
        "setup-monitoring")
            setup_monitoring
            ;;
        "plan")
            check_prerequisites
            for region in "${REGIONS[@]}"; do
                init_terraform "${region}"
                plan_terraform "${region}"
            done
            ;;
        *)
            echo "Usage: $0 {deploy|destroy|validate|setup-monitoring|plan}"
            echo ""
            echo "Commands:"
            echo "  deploy           - Deploy infrastructure to all regions"
            echo "  destroy          - Destroy infrastructure in all regions"
            echo "  validate         - Validate deployment with health checks"
            echo "  setup-monitoring - Setup monitoring stack"
            echo "  plan             - Plan deployment without applying"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"