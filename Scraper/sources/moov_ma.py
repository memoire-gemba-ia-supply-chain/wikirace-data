"""
Scraper for MOOV.MA - Moroccan Running Calendar
Fetches Marathons, Semi-Marathons, and Trails.
"""
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import sys
import re
from pathlib import Path

# Add parent to path to import models
sys.path.append(str(Path(__file__).parent.parent))
from models import RaceEvent

def clean_text(text):
    if not text:
        return ""
    return text.strip().replace('\xa0', ' ')

def parse_month(month_str):
    """Convert French month name to number"""
    months = {
        'jan': 1, 'janv': 1, 'janvier': 1,
        'fév': 2, 'fev': 2, 'février': 2, 'fevrier': 2,
        'mar': 3, 'mars': 3,
        'avr': 4, 'avril': 4,
        'mai': 5,
        'juin': 6,
        'juil': 7, 'juillet': 7,
        'août': 8, 'aout': 8,
        'sep': 9, 'sept': 9, 'septembre': 9,
        'oct': 10, 'octobre': 10,
        'nov': 11, 'novembre': 11,
        'déc': 12, 'dec': 12, 'décembre': 12, 'decembre': 12
    }
    key = month_str.lower().replace('.', '').strip()
    return months.get(key, 0)

def fetch_moov_ma_events() -> list[RaceEvent]:
    print("🇲🇦 Scraping Moov.ma for Moroccan Events...")
    
    # Moov.ma seems to list all courses on this page or via category links
    # Based on the HTML we saw, there is a main courses page: https://moov.ma/courses
    # But the home page also had lists. The most reliable might be the main listing.
    
    # We'll use the search page which seems to list everything or specific category pages if needed.
    # Let's try to scrape the main /courses page which aggregates everything.
    url = "https://moov.ma/courses/?tribe_paged=1&tribe_event_display=list"
    
    # However, the user request showed specific categories in the menu: Marathons (12), Semis (13), Trails (15)
    # Let's hit these category URLs to be specific and avoid pagination hell if possible (though we might still need it).
    
    categories = [
        ("https://moov.ma/courses/liste/?tribe_eventcategory%5B0%5D=12", "Marathon"), # Marathons
        ("https://moov.ma/courses/liste/?tribe_eventcategory%5B0%5D=13", "Half Marathon"), # Semis
        ("https://moov.ma/courses/liste/?tribe_eventcategory%5B0%5D=15", "Trail"), # Trails
        ("https://moov.ma/courses/liste/?tribe_eventcategory%5B0%5D=14", "10km"), # 10km (Good to have)
    ]
    
    all_events = []
    seen_links = set()
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15'
    }

    processed_urls = []

    for cat_url, default_dist in categories:
        if cat_url in processed_urls:
            continue
        processed_urls.append(cat_url)
        
        print(f"  - Fetching {default_dist}s from {cat_url}...")
        
        try:
            response = requests.get(cat_url, headers=headers, timeout=15)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # The structure for the list view is different from the home page widgets.
            # Usually: div.tribe-events-calendar-list__event-row
            # Let's check the common class for events.
            
            # If the list view is standard tribe-events, we look for '.type-tribe_events'
            events_nodes = soup.select('.type-tribe_events')
            
            if not events_nodes:
                 # Fallback: maybe it uses the elementor grid we saw on homepage? 
                 # But the URLs provided are 'tribe_eventcategory', implying The Events Calendar plugin.
                 # Let's assume standard tribe classes first.
                 pass

            for node in events_nodes:
                try:
                    # Title & Link
                    title_tag = node.select_one('.tribe-events-calendar-list__event-title-link')
                    if not title_tag:
                         # Try different selector if standard one fails
                         title_tag = node.select_one('.tribe-event-url')
                    
                    if not title_tag:
                        continue
                        
                    name = clean_text(title_tag.get_text())
                    link = title_tag.get('href')
                    
                    if link in seen_links:
                        continue
                    seen_links.add(link)
                    
                    # Date
                    # Usually inside .tribe-event-schedule-details or similar
                    date_tag = node.select_one('.tribe-event-date-start')
                    time_tag = node.select_one('time')
                    
                    event_date_str = ""
                    if time_tag and time_tag.has_attr('datetime'):
                        event_date_str = time_tag['datetime'][:10] # YYYY-MM-DD
                    
                    # Location
                    venue_tag = node.select_one('.tribe-events-calendar-list__event-venue-title')
                    address_tag = node.select_one('.tribe-events-calendar-list__event-venue-address')
                    
                    city = "Morocco"
                    if venue_tag:
                        city = clean_text(venue_tag.get_text())
                    elif address_tag:
                         city = clean_text(address_tag.get_text())
                         
                    # Image
                    img_tag = node.select_one('.tribe-events-calendar-list__event-featured-image-wrapper img')
                    img_url = img_tag.get('src') if img_tag else None
                    
                    # Description
                    desc_tag = node.select_one('.tribe-events-calendar-list__event-description')
                    desc = clean_text(desc_tag.get_text()) if desc_tag else ""
                    
                    # Cost
                    cost_tag = node.select_one('.tribe-events-calendar-list__event-cost')
                    price_text = clean_text(cost_tag.get_text()) if cost_tag else None
                    
                    # Distances (heuristic from title or desc)
                    distances = []
                    if "42k" in name.lower() or "marathon" in name.lower(): distances.append("42km")
                    if "21k" in name.lower() or "semi" in name.lower(): distances.append("21km")
                    if "10k" in name.lower(): distances.append("10km")
                    
                    # Create Event
                    race = RaceEvent(
                        id=RaceEvent.generate_id(name, event_date_str),
                        name=name,
                        date=event_date_str,
                        city=city,
                        country="Morocco",
                        countryCode="MA",
                        discipline="Trail" if "Trail" in name else "Running",
                        distance=default_dist,
                        elevationGain=None,
                        description=desc[:200] + "...",
                        registrationUrl=link,
                        imageUrl=img_url,
                        price=price_text,
                        currency="MAD",
                        registrationStatus="Open",
                        availableDistances=distances if distances else [default_dist],
                        gpxUrl=None
                    )
                    all_events.append(race)
                    
                except Exception as e:
                    print(f"    ⚠️ Error parsing event node: {e}")
                    continue
                    
        except Exception as e:
            print(f"  ❌ Failed to fetch category {default_dist}: {e}")

    # Fallback: if 'tribe' selectors failed (likely because I guessed classes), 
    # let's try scraping the homepage widgets we SAW in the HTML earlier.
    # The homepage had everything aggregated nicely.
    
    if len(all_events) < 5:
        print("  ⚠️ Category crawl yielded few results. Trying Homepage Widget parsing...")
        try:
            home_response = requests.get("https://moov.ma/", headers=headers, timeout=15)
            home_soup = BeautifulSoup(home_response.content, 'html.parser')
            
            # The homepage has swiper-slides with class 'ewpe-inner-wrapper'
            # We identified these in the user provided view_file output.
            
            slides = home_soup.select('.ewpe-inner-wrapper')
            current_year = datetime.now().year
            
            for slide in slides:
                try:
                    # Title
                    title_node = slide.select_one('.ewpe-event-title')
                    if not title_node: continue
                    name = clean_text(title_node.get_text())
                    
                    link_node = slide.select_one('a.event-link')
                    link = link_node['href'] if link_node else None
                    if not link or link in seen_links: continue
                    seen_links.add(link)
                    
                    # Date Logic (Complex because year might be missing)
                    # We have .ewpe-end-date spans. First is usually Month, second is Day (or vice versa? HTML showed Month then Day in separate widgets)
                    # Actually HTML showed:
                    # <div class="ewpe-events-schedule"><span class="ewpe-end-date">Oct</span></div>
                    # <div class="ewpe-events-schedule"><span class="ewpe-end-date">25</span></div>
                    
                    date_spans = slide.select('.ewpe-end-date')
                    if len(date_spans) >= 2:
                        month_str = clean_text(date_spans[0].get_text())
                        day_str = clean_text(date_spans[1].get_text())
                        
                        # Sometimes order is swapped or different? Let's assume Month is alpha, Day is numeric
                        if day_str.isalpha() and month_str.isdigit():
                            month_str, day_str = day_str, month_str
                            
                        month_num = parse_month(month_str)
                        if month_num and day_str.isdigit():
                            day_num = int(day_str)
                            
                            # Determine Year: If month is earlier than current month, assume next year
                            now = datetime.now()
                            year = now.year
                            if month_num < now.month - 1: # generous buffer
                                year += 1
                                
                            event_date_str = f"{year}-{month_num:02d}-{day_num:02d}"
                        else:
                            event_date_str = (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d") # Fallback
                    else:
                        continue # Can't find date
                        
                    # City
                    city_node = slide.select_one('.ewpe-event-venue-details')
                    city = clean_text(city_node.get_text()) if city_node else "Morocco"
                    
                    # Distances
                    dist_node = slide.select_one('.ewpe-acf-chk-fields')
                    dist_text = clean_text(dist_node.get_text()) if dist_node else ""
                    distances = [d.strip() for d in dist_text.split(',')]
                    
                    # Image
                    img_node = slide.select_one('.ewpe-featured-img img')
                    img_url = img_node.get('data-src') or img_node.get('src') if img_node else None
                    
                    race = RaceEvent(
                        id=RaceEvent.generate_id(name, event_date_str),
                        name=name,
                        date=event_date_str,
                        city=city,
                        country="Morocco",
                        countryCode="MA",
                        discipline="Trail" if "Trail" in name else "Running",
                        distance=distances[0] if distances else "Running",
                        elevationGain=None,
                        description=f"Distances: {dist_text}",
                        registrationUrl=link,
                        imageUrl=img_url,
                        price=None,
                        currency="MAD",
                        registrationStatus="Open",
                        availableDistances=distances,
                        gpxUrl=None
                    )
                    all_events.append(race)
                    
                except Exception as e:
                    pass

        except Exception as e:
            print(f"  ❌ Failed to parse homepage: {e}")

    print(f"✅ Moov.ma: Scraped {len(all_events)} events.")
    return all_events
