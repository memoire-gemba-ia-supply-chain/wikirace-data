#!/usr/bin/env python3
"""
WikiRace Event Scraper - Main Entry Point
Aggregates events from multiple sources and outputs JSON
"""
import json
import sys
from datetime import datetime
from pathlib import Path

# Add parent to path for imports
BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(Path(__file__).parent))

from models import RaceEvent
from sources.runsignup import fetch_runsignup_events
from sources.itra import fetch_itra_events
from sources.ultrasignup import fetch_ultrasignup_events
from sources.morocco import fetch_moroccan_events
from sources.triathlon import fetch_triathlon_events


def deduplicate_events(events: list[RaceEvent]) -> list[RaceEvent]:
    """Remove duplicate events based on name similarity and date"""
    seen = set()
    unique = []
    
    for event in events:
        # Create a key based on normalized name and date
        key = (event.name.lower().strip(), event.date)
        if key not in seen:
            seen.add(key)
            unique.append(event)
    
    return unique


def sort_events(events: list[RaceEvent]) -> list[RaceEvent]:
    """Sort events by date"""
    return sorted(events, key=lambda e: e.date)


def main():
    print("🏃 WikiRace Event Scraper")
    print("=" * 40)
    
    all_events = []
    
    # Fetch from all sources
    print("\n📡 Fetching from RunSignup API...")
    try:
        all_events.extend(fetch_runsignup_events(max_results=500))
    except Exception as e:
        print(f"⚠️ RunSignup failed: {e}")
    
    print("\n🇲🇦 Fetching Specialized Morocco Events...")
    try:
        all_events.extend(fetch_moroccan_events())
    except Exception as e:
        print(f"⚠️ Morocco Source failed: {e}")

    print("\n🏊🚴🏃 Fetching Triathlon & Ironman Events...")
    try:
        all_events.extend(fetch_triathlon_events())
    except Exception as e:
        print(f"⚠️ Triathlon Source failed: {e}")

    print("\n🏔️ Fetching from ITRA...")
    try:
        all_events.extend(fetch_itra_events(max_results=200))
    except Exception as e:
        print(f"⚠️ ITRA failed: {e}")
    
    print("\n🏃‍♂️ Fetching from UltraSignup...")
    try:
        all_events.extend(fetch_ultrasignup_events(max_results=100))
    except Exception as e:
        print(f"⚠️ UltraSignup failed: {e}")
    
    # Process events
    print("\n🔄 Processing events...")
    events = deduplicate_events(all_events)
    events = sort_events(events)
    
    # Filter future events only
    today = datetime.now().strftime("%Y-%m-%d")
    events = [e for e in events if e.date >= today]
    
    print(f"\n📊 Total unique events: {len(events)}")
    
    # Create output
    output = {
        "lastUpdated": datetime.now().isoformat(),
        "totalEvents": len(events),
        "events": [e.to_dict() for e in events]
    }
    
    # Write to file
    output_path = Path(__file__).parent.parent / "events.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Saved to: {output_path}")
    print(f"📅 Last updated: {output['lastUpdated']}")
    
    # Run audit/fix automatically
    print("\n🔍 Running data audit and fixes...")
    from audit_fix import audit_and_fix
    audit_and_fix()
    
    # Run dedicated GPX scraper
    print("\n🌐 Running dedicated GPX scraper...")
    from sources.gpx_scraper import run_gpx_scraper
    run_gpx_scraper()
    
    # Run active URL validation
    print("\n🛡️ Running active URL validation and cleanup...")
    from url_validator import validate_data
    validate_data()
    
    # Sync to WikiRaceApp Export folder
    try:
        import shutil
        app_json_path = BASE_DIR / "WikiRaceApp_Export" / "WikiRaceApp" / "events.json"
        if app_json_path.parent.exists():
            shutil.copy2(output_path, app_json_path)
            print(f"🔄 Synced to App: {app_json_path}")
    except Exception as e:
        print(f"⚠️ Sync failed: {e}")
    
    # Show sample events
    print("\n📋 Sample events:")
    for event in events[:10]:
        print(f"  - {event.name} | {event.date} | {event.city}, {event.country}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
