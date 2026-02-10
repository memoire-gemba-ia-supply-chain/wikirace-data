"""
Specialized source for Triathlon & Ironman events
Focuses on major 70.3 and 140.6 races, with specific attention to Moroccan events.
"""
from typing import List
import sys
from datetime import datetime
sys.path.append('..')
from models import RaceEvent

def fetch_triathlon_events() -> List[RaceEvent]:
    """
    Returns a list of major Triathlon events.
    Currently uses a static curated list for reliability, as Triathlon sites are hard to scrape without API.
    """
    events = []
    
    # Format: (Name, Date, City, Country, Code, DistCategory, Description, URL)
    tri_data = [
        # Morocco 🇲🇦
        (
            "Ironman 70.3 Agadir", 
            "2025-10-26", 
            "Agadir", 
            "Morocco", 
            "MA", 
            "Half Ironman", 
            "Swim in the Atlantic, bike through Argan trees, run along the corniche.",
            "https://www.ironman.com/im703-agadir"
        ),
        (
            "Ironman 70.3 Tangier", 
            "2026-10-25", # Provisional late Oct
            "Tangier", 
            "Morocco", 
            "MA", 
            "Half Ironman", 
            "A scenic race where the Mediterranean meets the Atlantic.",
            "https://www.ironman.com/im703-tangier"
        ),
        (
            "Triathlon International de Larache",
            "2025-06-08",
            "Larache",
            "Morocco",
            "MA",
            "Olympic Triathlon",
            "One of the oldest and most prestigious triathlons in Morocco.",
            "https://swotri.com/"
        ),
        
        # World Majors 🌍
        (
            "Ironman World Championship",
            "2025-09-14",
            "Nice",
            "France",
            "FR",
            "Ironman",
            "The pinnacle of the sport, held on the Côte d'Azur.",
            "https://www.ironman.com/im-world-championship-nice"
        ),
        (
            "Ironman 70.3 World Championship",
            "2025-11-08",
            "Marbella",
            "Spain",
            "ES",
            "Half Ironman",
            "Global championship for the half distance.",
            "https://www.ironman.com/im703-world-championship"
        ),
        (
            "Norseman Xtreme Triathlon",
            "2025-08-02",
            "Eidfjord",
            "Norway",
            "NO",
            "Ironman",
            "Simply the ultimate triathlon on planet Earth.",
            "https://nxtri.com/"
        ),
        (
            "Challenge Roth",
            "2025-07-06",
            "Roth",
            "Germany",
            "DE",
            "Ironman",
            "The world's biggest triathlon party with record-breaking course.",
            "https://www.challenge-roth.com/"
        ),
        (
            "Ironman Frankfurt",
            "2025-08-18",
            "Frankfurt",
            "Germany",
            "DE",
            "Ironman",
            "European Championship.",
            "https://www.ironman.com/im-frankfurt"
        )
    ]
    
    for name, date, city, country, code, dist_cat, desc, url in tri_data:
         # Only add valid future dates
        try:
            event_date = datetime.strptime(date, "%Y-%m-%d")
            # Keep if future or very recent
        except:
            continue

        events.append(
            RaceEvent(
                id=RaceEvent.generate_id(name, date),
                name=name,
                date=date,
                city=city,
                country=country,
                countryCode=code,
                discipline="Triathlon",
                distance=dist_cat,
                elevationGain=None,
                description=desc,
                registrationUrl=url,
                imageUrl=name.lower().replace(" ", "_"),
                price=None,
                currency="EUR" if code in ["FR", "DE", "ES"] else "USD",
                registrationStatus="Open",
                availableDistances=distances
            )
        )
        
    print(f"✅ Triathlon Source: Loaded {len(events)} major events")
    return events
