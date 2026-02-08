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
sys.path.insert(0, str(Path(__file__).parent))

from models import RaceEvent
from sources.runsignup import fetch_runsignup_events
from sources.itra import fetch_itra_events
from sources.ultrasignup import fetch_ultrasignup_events


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
    all_events.extend(fetch_runsignup_events(max_results=50))
    
    print("\n🏔️ Fetching from ITRA...")
    all_events.extend(fetch_itra_events(max_results=50))
    
    print("\n🏃‍♂️ Fetching from UltraSignup...")
    all_events.extend(fetch_ultrasignup_events(max_results=30))
    
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
    
    # Show sample events
    print("\n📋 Sample events:")
    for event in events[:10]:
        print(f"  - {event.name} | {event.date} | {event.city}, {event.country}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
