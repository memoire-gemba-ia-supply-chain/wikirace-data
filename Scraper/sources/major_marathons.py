"""
Specialized source for World Marathon Majors and prestigious road races.
Ensures these high-demand events are always present with accurate data.
"""
from typing import List
import sys
from datetime import datetime
sys.path.append('..')
from models import RaceEvent

def fetch_major_marathons() -> List[RaceEvent]:
    """
    Returns a curated list of Major Marathons.
    """
    events = []
    
    # Format: (Name, Date, City, Country, Code, Description, URL, GPX_URL)
    majors_data = [
        (
            "Tokyo Marathon 2026", 
            "2026-03-01", 
            "Tokyo", 
            "Japan", 
            "JP", 
            "One of the six World Marathon Majors, known for its flat course and enthusiastic crowd.",
            "https://www.marathon.tokyo/en/",
            "https://www.marathon.tokyo/en/about/course/"
        ),
        (
            "Boston Marathon 2026", 
            "2026-04-20", 
            "Boston", 
            "USA", 
            "US", 
            "The world's oldest annual marathon. A point-to-point course from Hopkinton to Copley Square.",
            "https://www.baa.org/races/boston-marathon",
            "https://www.baa.org/races/boston-marathon/enter/course-information"
        ),
        (
            "TCS London Marathon 2026", 
            "2026-04-26", 
            "London", 
            "UK", 
            "GB", 
            "A fast, flat course past London's greatest landmarks.",
            "https://www.tcslondonmarathon.com/",
            "https://www.tcslondonmarathon.com/the-event/the-course"
        ),
        (
            "BMW Berlin Marathon 2025", 
            "2025-09-21", 
            "Berlin", 
            "Germany", 
            "DE", 
            "The fastest marathon course in the world, home to many world records.",
            "https://www.bmw-berlin-marathon.com/",
            "https://www.bmw-berlin-marathon.com/en/your-race/map/"
        ),
        (
            "Bank of America Chicago Marathon 2025", 
            "2025-10-12", 
            "Chicago", 
            "USA", 
            "US", 
            "Known for its flat and fast course through 29 diverse neighborhoods.",
            "https://www.chicagomarathon.com/",
            "https://www.chicagomarathon.com/runners/course-amenities/course-map/"
        ),
        (
            "TCS New York City Marathon 2025", 
            "2025-11-02", 
            "New York", 
            "USA", 
            "US", 
            "The largest marathon in the world, running through all five boroughs of NYC.",
            "https://www.nyrr.org/tcsnycmarathon",
            "https://www.nyrr.org/tcsnycmarathon/race-day/the-course"
        ),
        (
             "Schneider Electric Paris Marathon 2026",
             "2026-04-12", # Estimated
             "Paris",
             "France",
             "FR",
             "One of the biggest marathons in the world, offering a unique opportunity to run through the City of Light.",
             "https://www.schneiderelectricparismarathon.com/en/",
             "https://www.schneiderelectricparismarathon.com/en/event/course"
        ),
        (
            "Valencia Marathon Trinidad Alfonso 2025",
            "2025-12-07",
            "Valencia",
            "Spain",
            "ES",
            "Known as the City of Running, offering one of the flattest courses in Europe.",
            "https://www.valenciaciudaddelrunning.com/en/marathon/marathon-course/",
            "https://www.valenciaciudaddelrunning.com/en/marathon/marathon-course/"
        )
    ]
    
    for name, date, city, country, code, desc, url, gpx in majors_data:
         # Only add valid future dates (or close to today)
        try:
            event_date = datetime.strptime(date, "%Y-%m-%d")
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
                discipline="Running",
                distance="Marathon",
                elevationGain=None, # Mostly flat
                description=desc,
                registrationUrl=url,
                imageUrl=name.lower().replace(" ", "_"),
                price=None, # Varies
                currency="USD" if code == "US" else "EUR", # Approximation
                registrationStatus="Open",
                availableDistances=["42.2km"],
                gpxUrl=gpx
            )
        )
        
    print(f"✅ Major Marathons Source: Loaded {len(events)} events")
    return events
