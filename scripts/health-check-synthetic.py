#!/usr/bin/env python3
"""
Sleek Multi-Region Health Check and Synthetic Transaction Script
Simulates real user transactions across all regions for comprehensive monitoring
"""

import asyncio
import aiohttp
import time
import json
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional
import argparse
from dataclasses import dataclass, asdict
import statistics

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('synthetic_transactions.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class RegionConfig:
    name: str
    endpoint: str
    expected_response_time_ms: int
    country: str

@dataclass
class TransactionResult:
    region: str
    transaction_type: str
    status_code: int
    response_time_ms: float
    success: bool
    timestamp: str
    error: Optional[str] = None

class SyntheticTransactionEngine:
    def __init__(self):
        self.regions = [
            RegionConfig("singapore", "https://singapore-lb.sleek-monitor.local", 200, "Singapore"),
            RegionConfig("hongkong", "https://hongkong-lb.sleek-monitor.local", 250, "Hong Kong"),
            RegionConfig("australia", "https://australia-lb.sleek-monitor.local", 300, "Australia"),
            RegionConfig("uk", "https://uk-lb.sleek-monitor.local", 400, "United Kingdom")
        ]
        self.results: List[TransactionResult] = []
        
    async def perform_health_check(self, session: aiohttp.ClientSession, region: RegionConfig) -> TransactionResult:
        """Perform basic health check"""
        start_time = time.time()
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            async with session.get(f"{region.endpoint}/health", timeout=aiohttp.ClientTimeout(total=10)) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # Convert to milliseconds
                
                success = response.status == 200
                
                return TransactionResult(
                    region=region.name,
                    transaction_type="health_check",
                    status_code=response.status,
                    response_time_ms=response_time,
                    success=success,
                    timestamp=timestamp
                )
                
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return TransactionResult(
                region=region.name,
                transaction_type="health_check",
                status_code=0,
                response_time_ms=response_time,
                success=False,
                timestamp=timestamp,
                error=str(e)
            )

    async def perform_user_login_simulation(self, session: aiohttp.ClientSession, region: RegionConfig) -> TransactionResult:
        """Simulate user login transaction"""
        start_time = time.time()
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            # Simulate POST login request
            login_data = {
                "username": "test.user@sleek.com",
                "password": "synthetic_test_password",
                "region": region.country,
                "transaction_id": f"syn_{int(time.time())}"
            }
            
            async with session.post(
                f"{region.endpoint}/api/auth/login",
                json=login_data,
                timeout=aiohttp.ClientTimeout(total=15)
            ) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000
                
                # For synthetic testing, accept various response codes as "successful"
                success = response.status in [200, 201, 401, 404]  # 401/404 expected for synthetic endpoints
                
                return TransactionResult(
                    region=region.name,
                    transaction_type="user_login",
                    status_code=response.status,
                    response_time_ms=response_time,
                    success=success,
                    timestamp=timestamp
                )
                
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return TransactionResult(
                region=region.name,
                transaction_type="user_login",
                status_code=0,
                response_time_ms=response_time,
                success=False,
                timestamp=timestamp,
                error=str(e)
            )

    async def perform_data_query_simulation(self, session: aiohttp.ClientSession, region: RegionConfig) -> TransactionResult:
        """Simulate financial data query transaction"""
        start_time = time.time()
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            # Simulate financial services data query
            query_params = {
                "account_id": "ACC123456789",
                "date_from": "2024-01-01",
                "date_to": "2024-01-31",
                "transaction_type": "all"
            }
            
            async with session.get(
                f"{region.endpoint}/api/financial/transactions",
                params=query_params,
                timeout=aiohttp.ClientTimeout(total=20)
            ) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000
                
                # Check if response time meets financial services requirements (< 500ms)
                compliance_check = response_time < 500
                success = response.status in [200, 404] and compliance_check
                
                return TransactionResult(
                    region=region.name,
                    transaction_type="financial_query",
                    status_code=response.status,
                    response_time_ms=response_time,
                    success=success,
                    timestamp=timestamp,
                    error=None if compliance_check else f"Response time {response_time:.2f}ms exceeds 500ms compliance limit"
                )
                
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return TransactionResult(
                region=region.name,
                transaction_type="financial_query",
                status_code=0,
                response_time_ms=response_time,
                success=False,
                timestamp=timestamp,
                error=str(e)
            )

    async def run_synthetic_transactions(self) -> Dict:
        """Run all synthetic transactions across all regions"""
        connector = aiohttp.TCPConnector(limit=100, limit_per_host=10)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            tasks = []
            
            # Create tasks for all regions and transaction types
            for region in self.regions:
                tasks.extend([
                    self.perform_health_check(session, region),
                    self.perform_user_login_simulation(session, region),
                    self.perform_data_query_simulation(session, region)
                ])
            
            # Execute all tasks concurrently
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            valid_results = []
            for result in results:
                if isinstance(result, TransactionResult):
                    valid_results.append(result)
                    self.results.append(result)
                else:
                    logger.error(f"Task failed with exception: {result}")
            
            return self.analyze_results(valid_results)

    def analyze_results(self, results: List[TransactionResult]) -> Dict:
        """Analyze transaction results and generate metrics"""
        if not results:
            return {"error": "No results to analyze"}
        
        analysis = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "total_transactions": len(results),
            "successful_transactions": sum(1 for r in results if r.success),
            "failed_transactions": sum(1 for r in results if not r.success),
            "overall_success_rate": (sum(1 for r in results if r.success) / len(results)) * 100,
            "regions": {},
            "transaction_types": {},
            "sla_compliance": {},
            "response_times": {
                "min": min(r.response_time_ms for r in results),
                "max": max(r.response_time_ms for r in results),
                "avg": statistics.mean(r.response_time_ms for r in results),
                "median": statistics.median(r.response_time_ms for r in results)
            }
        }
        
        # Analyze by region
        for region in set(r.region for r in results):
            region_results = [r for r in results if r.region == region]
            region_success_rate = (sum(1 for r in region_results if r.success) / len(region_results)) * 100
            
            analysis["regions"][region] = {
                "total": len(region_results),
                "successful": sum(1 for r in region_results if r.success),
                "success_rate": region_success_rate,
                "avg_response_time": statistics.mean(r.response_time_ms for r in region_results),
                "sla_compliant": region_success_rate >= 99.99
            }
        
        # Analyze by transaction type
        for tx_type in set(r.transaction_type for r in results):
            tx_results = [r for r in results if r.transaction_type == tx_type]
            tx_success_rate = (sum(1 for r in tx_results if r.success) / len(tx_results)) * 100
            
            analysis["transaction_types"][tx_type] = {
                "total": len(tx_results),
                "successful": sum(1 for r in tx_results if r.success),
                "success_rate": tx_success_rate,
                "avg_response_time": statistics.mean(r.response_time_ms for r in tx_results)
            }
        
        # SLA compliance analysis
        analysis["sla_compliance"] = {
            "target_availability": 99.99,
            "current_availability": analysis["overall_success_rate"],
            "compliance_status": "COMPLIANT" if analysis["overall_success_rate"] >= 99.99 else "NON_COMPLIANT",
            "financial_services_latency": {
                "target_ms": 500,
                "violations": len([r for r in results if r.transaction_type == "financial_query" and r.response_time_ms > 500])
            }
        }
        
        return analysis

    def export_results(self, analysis: Dict, format_type: str = "json"):
        """Export results to various formats"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        if format_type == "json":
            filename = f"synthetic_results_{timestamp}.json"
            with open(filename, 'w') as f:
                json.dump(analysis, f, indent=2)
            logger.info(f"Results exported to {filename}")
        
        # Export individual transaction results
        csv_filename = f"transaction_details_{timestamp}.csv"
        with open(csv_filename, 'w') as f:
            f.write("timestamp,region,transaction_type,status_code,response_time_ms,success,error\n")
            for result in self.results:
                f.write(f"{result.timestamp},{result.region},{result.transaction_type},"
                       f"{result.status_code},{result.response_time_ms:.2f},{result.success},"
                       f"\"{result.error or ''}\"\n")
        logger.info(f"Transaction details exported to {csv_filename}")

async def main():
    parser = argparse.ArgumentParser(description="Sleek Multi-Region Synthetic Transaction Monitor")
    parser.add_argument("--continuous", action="store_true", help="Run continuously with 60-second intervals")
    parser.add_argument("--export-format", choices=["json", "csv"], default="json", help="Export format")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    engine = SyntheticTransactionEngine()
    
    if args.continuous:
        logger.info("Starting continuous monitoring mode (60-second intervals)")
        while True:
            try:
                logger.info("Executing synthetic transaction suite...")
                analysis = await engine.run_synthetic_transactions()
                
                # Log key metrics
                logger.info(f"Overall success rate: {analysis['overall_success_rate']:.2f}%")
                logger.info(f"Average response time: {analysis['response_times']['avg']:.2f}ms")
                logger.info(f"SLA compliance: {analysis['sla_compliance']['compliance_status']}")
                
                # Export results
                engine.export_results(analysis, args.export_format)
                
                # Wait 60 seconds before next run
                await asyncio.sleep(60)
                
            except KeyboardInterrupt:
                logger.info("Stopping continuous monitoring...")
                break
            except Exception as e:
                logger.error(f"Error in continuous monitoring: {e}")
                await asyncio.sleep(10)  # Wait 10 seconds before retrying
    else:
        logger.info("Executing single synthetic transaction suite...")
        analysis = await engine.run_synthetic_transactions()
        
        # Print summary
        print(f"\n{'='*50}")
        print("SLEEK MULTI-REGION HEALTH CHECK SUMMARY")
        print(f"{'='*50}")
        print(f"Total Transactions: {analysis['total_transactions']}")
        print(f"Success Rate: {analysis['overall_success_rate']:.2f}%")
        print(f"Average Response Time: {analysis['response_times']['avg']:.2f}ms")
        print(f"SLA Compliance: {analysis['sla_compliance']['compliance_status']}")
        print(f"\nRegion Performance:")
        for region, data in analysis['regions'].items():
            print(f"  {region.capitalize()}: {data['success_rate']:.2f}% ({data['avg_response_time']:.2f}ms avg)")
        
        # Export results
        engine.export_results(analysis, args.export_format)

if __name__ == "__main__":
    asyncio.run(main())