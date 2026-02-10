"""
Specialized source for Moroccan Trail & Running events
Ensures high priority events are always present with accurate data.
"""
from typing import List
import sys
from datetime import datetime
sys.path.append('..')
from models import RaceEvent

def fetch_moroccan_events() -> List[RaceEvent]:
    """
    Returns a curated list of Moroccan events that might be missed by global scrapers.
    Acts as a 'Source of Truth' for local events.
    """
    events = []
    
    # Official Calendar Data (Curated)
    # Format: (Name, Date, City, Distance Category, Elevation, Description, URL, [Distances], GPX_URL)
    # Official Calendar Data (Curated)
    # Format: (Name, Date, City, Distance Category, Elevation, Description, URL, [Distances], GPX_URL)
    local_data = [
        # Static data disabled in favor of moov.ma dynamic scraper
        # (
        #    "Trail Amizmiz", 
        #    "2026-04-25", 
        #    ...
        # )
    ]
    
    for name, date, city, distance_cat, elev, desc, url, distances, gpx_url in local_data:
        # Only add valid future dates (or close to today)
        try:
            event_date = datetime.strptime(date, "%Y-%m-%d")
            # We allow recent past for critical events to show up (and filter later if needed)
        except:
            continue

        events.append(
            RaceEvent(
                id=RaceEvent.generate_id(name, date),
                name=name,
                date=date,
                city=city,
                country="Morocco",
                countryCode="MA",
                discipline="Trail" if "Trail" in name or "Ultra" in name or distance_cat == "Ultra Trail" else "Running",
                distance=distance_cat,
                elevationGain=elev,
                description=desc,
                registrationUrl=url,
                imageUrl=name.lower().replace(" ", "_"),
                price=None,
                currency="MAD",
                registrationStatus="Open",
                availableDistances=distances,
                gpxUrl=gpx_url
            )
        )
        
    print(f"✅ Morocco Special Source: Loaded {len(events)} curated events")
    return events
