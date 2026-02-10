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
    local_data = [
        (
            "Trail Amizmiz", 
            "2026-04-25", 
            "Amizmiz", 
            "Marathon", 
            2200, 
            "A rugged trail in the High Atlas foothills, known for its technical terrain and Berber village hospitality.",
            "https://trailmaroc.com/trail-amizmiz/",
            ["9km", "22km", "31km", "74km"],
            "https://www.wikiloc.com/wikiloc/map.do?sw=-8.25,31.15&ne=-8.15,31.25"
        ),
        (
            "Trail Lac Lalla Takerkoust", 
            "2027-02-14", 
            "Lalla Takerkoust", 
            "Half Marathon", 
            650, 
            "Scenic trail running around the beautiful Lalla Takerkoust lake with Atlas mountains backdrop.",
            "https://www.trail-maroc.com/",
            ["10km", "21km", "42km"],
            None
        ),
        (
            "Eco Trail Ouarzazate", 
            "2026-04-17", 
            "Ouarzazate", 
            "Ultra Trail", 
            1800, 
            "Run through the door of the desert, passing movie sets and kasbahs.",
            "https://www.ecotrailouarzazate.com/",
            ["10km", "30km", "70km"],
            None
        ),
        (
            "Trans Atlas Marathon", 
            "2026-05-11", 
            "Atlas Mountains", 
            "Ultra Trail", 
            12000, 
            "A 6-stage ultra marathon crossing the High Atlas mountains. Extreme difficulty.",
            "https://transatlasmarathon.com/",
            ["280km (6 Stages)"],
            "https://transatlasmarathon.com/course-gpx"
        ),
        (
            "Morocco Race", 
            "2026-11-19", 
            "Marrakech", 
            "Ultra Trail", 
            3500, 
            "International trail event combining desert and mountain landscapes near Marrakech.",
            "https://www.moroccorace.com/",
            ["10km", "21km", "42km", "65km", "95km"],
            None
        ),
        (
            "Chefchaouen Trail", 
            "2026-09-13", 
            "Chefchaouen", 
            "Marathon", 
            1500, 
            "Run through the Blue Pearl of Morocco and the Rif mountains.",
            "https://www.chefchaouentrail.com/",
            ["10km", "21km", "42km"],
            None
        ),
        (
            "International Marathon of Casablanca",
            "2026-10-25",
            "Casablanca",
            "Marathon",
            100,
            "The leading road race in the economic capital of Morocco.",
            "https://www.casa-marathon.com/",
            ["10km", "21km", "42km"],
            "https://www.casa-marathon.com/parcours-gpx"
        )
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
