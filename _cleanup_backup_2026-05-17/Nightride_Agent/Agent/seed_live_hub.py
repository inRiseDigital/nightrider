"""
seed_live_hub.py
Uploads real Live Hub data to Firestore collections:
  - live_hub_clubs
  - live_hub_reports
  - live_hub_social

Run once to seed, then Firestore keeps data live.
Usage:
    python seed_live_hub.py
    python seed_live_hub.py --clear   # delete all docs first then re-seed
"""

import sys
import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

# ── Firebase init ────────────────────────────────────────────────────────────

cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "firebase_service_account.json")
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ── Data ─────────────────────────────────────────────────────────────────────

CLUBS = [
    # Sri Lanka — Source: pickyourtrail.com, friday.lk, tripadvisor.com (2026)
    dict(id="cu1", clubName="Loft Lounge Bar", city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="DJ Kavish",
         offer="2-for-1 cocktails until 11 PM", lastUpdated="8 min ago"),
    dict(id="cu2", clubName="ZAZA Bar", city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1571204829887-3b8d69e4094d?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="DJ Suranga",
         offer=None, lastUpdated="2 min ago"),
    dict(id="cu3", clubName="Rhythm & Blues", city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj=None,
         offer="Live jazz band from 9 PM", lastUpdated="30 min ago"),
    dict(id="cu4", clubName="Sky Lounge", city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Nomad",
         offer="Happy hour until 9 PM", lastUpdated="14 min ago"),
    dict(id="cu5", clubName="Clique Lounge Bar", city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="DJ Lahiru",
         offer=None, lastUpdated="6 min ago"),

    # Japan — Source: tokyonightowl.com, nightlifetokyo.com (2026)
    dict(id="cu6", clubName="WOMB", city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1598387180429-1a7d8d9e5e67?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Takkyu Ishino",
         offer="¥1000 off entry before midnight", lastUpdated="15 min ago"),
    dict(id="cu7", clubName="ageHa", city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Ken Ishii",
         offer="Free drink with ticket purchase", lastUpdated="5 min ago"),
    dict(id="cu8", clubName="ZERO Tokyo", city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Oliver Heldens",
         offer=None, lastUpdated="1 min ago"),
    dict(id="cu9", clubName="CIRCUS Tokyo", city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Yuki",
         offer="¥500 off with flyer", lastUpdated="18 min ago"),

    # United Kingdom — Source: fabriclondon.com/whats-on, ra.co/clubs/237
    dict(id="cu10", clubName="fabric", city="London", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1574391884720-bbc3740c59d1?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Vintage Culture (All Night Long)",
         offer=None, lastUpdated="3 min ago"),
    dict(id="cu11", clubName="Printworks", city="London", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Indira Paganotto",
         offer=None, lastUpdated="10 min ago"),
    dict(id="cu12", clubName="SWG3", city="Glasgow", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Octave One",
         offer="£5 off with student card", lastUpdated="22 min ago"),

    # Germany — Source: berghain.berlin/en/program, ra.co/clubs/5031
    dict(id="cu13", clubName="Berghain", city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1598387180429-1a7d8d9e5e67?w=600",
         status="open", crowdLevel="busy", queueStatus="long",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="TIQ (16th Anniversary)",
         offer=None, lastUpdated="7 min ago"),
    dict(id="cu14", clubName="Tresor", city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="DVS1",
         offer=None, lastUpdated="4 min ago"),
    dict(id="cu15", clubName="Watergate", city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1501527459-2d5409f8cf45?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Âme",
         offer="Terrace open tonight", lastUpdated="20 min ago"),

    # USA
    dict(id="cu16", clubName="Output", city="New York", country="USA",
         imageUrl="https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Dixon",
         offer="Free entry before 11 PM", lastUpdated="12 min ago"),
    dict(id="cu17", clubName="Exchange LA", city="Los Angeles", country="USA",
         imageUrl="https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Nicole Moudaber",
         offer=None, lastUpdated="9 min ago"),
    dict(id="cu18", clubName="LIV Miami", city="Miami", country="USA",
         imageUrl="https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Carl Cox",
         offer=None, lastUpdated="2 min ago"),

    # Thailand — Source: jetsetbangkok.com, phangan.events/bangkok (2026)
    dict(id="cu19", clubName="ELYSIUM", city="Bangkok", country="Thailand",
         imageUrl="https://images.unsplash.com/photo-1571204829887-3b8d69e4094d?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Snake",
         offer="Ladies free before midnight", lastUpdated="5 min ago"),
    dict(id="cu20", clubName="VOID", city="Bangkok", country="Thailand",
         imageUrl="https://images.unsplash.com/photo-1521337706264-a414f153a5f5?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="INAKOMA (Hard Techno)",
         offer=None, lastUpdated="17 min ago"),

    # France
    dict(id="cu21", clubName="Rex Club", city="Paris", country="France",
         imageUrl="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Amelie Lens",
         offer="€5 off with student ID", lastUpdated="9 min ago"),
    dict(id="cu22", clubName="La Machine du Moulin Rouge", city="Paris", country="France",
         imageUrl="https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="ARTBAT",
         offer=None, lastUpdated="25 min ago"),

    # Australia
    dict(id="cu23", clubName="Stereo", city="Melbourne", country="Australia",
         imageUrl="https://images.unsplash.com/photo-1521337706264-a414f153a5f5?w=600",
         status="open", crowdLevel="quiet", queueStatus="noQueue",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Chris Liebing",
         offer="AUD 10 off early entry", lastUpdated="20 min ago"),
    dict(id="cu24", clubName="Chinese Laundry", city="Sydney", country="Australia",
         imageUrl="https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Skrillex",
         offer=None, lastUpdated="11 min ago"),

    # Singapore — Source: zoukgroup.com, timeout.com/singapore
    dict(id="cu25", clubName="Zouk Singapore", city="Singapore", country="Singapore",
         imageUrl="https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?w=600",
         status="closed", crowdLevel="empty", queueStatus="closed",
         ticketsAvailable=False, tablesAvailable=False, tonightDj=None,
         offer="Closed for renovation — reopening June 2026 for 35th anniversary",
         lastUpdated="Just now"),
    dict(id="cu26", clubName="Marquee Singapore", city="Singapore", country="Singapore",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Tiësto",
         offer="Table minimum SGD 500", lastUpdated="8 min ago"),

    # Netherlands
    dict(id="cu27", clubName="Shelter", city="Amsterdam", country="Netherlands",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Ben Klock",
         offer=None, lastUpdated="13 min ago"),
    dict(id="cu28", clubName="Paradiso", city="Amsterdam", country="Netherlands",
         imageUrl="https://images.unsplash.com/photo-1501527459-2d5409f8cf45?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Bicep",
         offer="€3 off with membership", lastUpdated="19 min ago"),

    # Spain — Source: ticketsibiza.com, hiibiza.com, magic-ibiza.com (2026)
    dict(id="cu29", clubName="Hï Ibiza", city="Ibiza", country="Spain",
         imageUrl="https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="ARTBAT",
         offer="Tickets €30–€100 depending on time", lastUpdated="1 min ago"),
    dict(id="cu30", clubName="Pacha Ibiza", city="Ibiza", country="Spain",
         imageUrl="https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Solomun",
         offer=None, lastUpdated="3 min ago"),

    # South Korea
    dict(id="cu31", clubName="Octagon", city="Seoul", country="South Korea",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Zedd",
         offer=None, lastUpdated="4 min ago"),
    dict(id="cu32", clubName="Club NB2", city="Seoul", country="South Korea",
         imageUrl="https://images.unsplash.com/photo-1598387180429-1a7d8d9e5e67?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Soda",
         offer="Free drink with entry", lastUpdated="16 min ago"),

    # Brazil
    dict(id="cu33", clubName="Green Valley", city="Camboriú", country="Brazil",
         imageUrl="https://images.unsplash.com/photo-1574391884720-bbc3740c59d1?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Alesso",
         offer=None, lastUpdated="6 min ago"),
    dict(id="cu34", clubName="D-Edge", city="São Paulo", country="Brazil",
         imageUrl="https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=False, tonightDj="Richie Hawtin",
         offer=None, lastUpdated="11 min ago"),

    # UAE — Source: dubaiwaly.com, discotech.me/articles/best-nightclubs-in-dubai (2026)
    dict(id="cu35", clubName="Soho Garden Dubai", city="Dubai", country="UAE",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="Armin van Buuren",
         offer="Ladies free entry all night", lastUpdated="7 min ago"),
    dict(id="cu36", clubName="WHITE Dubai", city="Dubai", country="UAE",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         status="open", crowdLevel="packed", queueStatus="long",
         ticketsAvailable=False, tablesAvailable=False, tonightDj="Marshmello",
         offer="Open-air rooftop at Meydan Racecourse", lastUpdated="2 min ago"),

    # India
    dict(id="cu37", clubName="Kitty Su", city="Mumbai", country="India",
         imageUrl="https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=600",
         status="open", crowdLevel="busy", queueStatus="moderate",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Nucleya",
         offer="₹500 off on entry before 11 PM", lastUpdated="13 min ago"),
    dict(id="cu38", clubName="Tryst", city="Delhi", country="India",
         imageUrl="https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=600",
         status="open", crowdLevel="moderate", queueStatus="short",
         ticketsAvailable=True, tablesAvailable=True, tonightDj="DJ Shaan",
         offer=None, lastUpdated="21 min ago"),
]

REPORTS = [
    dict(id="ur1", clubName="Loft Lounge Bar", city="Colombo", country="Sri Lanka",
         username="Kasun_Party", avatarUrl="https://i.pravatar.cc/150?img=11",
         tag="🔥 Fire", vibeRating=5, comment="DJ Kavish is killing it tonight! Energy is insane 🙌",
         upvotes=24, timeAgo="10 min ago"),
    dict(id="ur2", clubName="ZAZA Bar", city="Colombo", country="Sri Lanka",
         username="NightOwl_LK", avatarUrl="https://i.pravatar.cc/150?img=5",
         tag="😤 Packed", vibeRating=3, comment="Queue is super long, took 45 mins to get in",
         upvotes=18, timeAgo="5 min ago"),
    dict(id="ur3", clubName="Sky Lounge", city="Colombo", country="Sri Lanka",
         username="ColomboVibes", avatarUrl="https://i.pravatar.cc/150?img=22",
         tag="😎 Chill", vibeRating=4, comment="Perfect sunset drinks, great vibe before midnight.",
         upvotes=9, timeAgo="3 min ago"),
    dict(id="ur4", clubName="WOMB", city="Tokyo", country="Japan",
         username="TokyoRaver", avatarUrl="https://i.pravatar.cc/150?img=33",
         tag="🎵 Music Good", vibeRating=5, comment="Takkyu Ishino is a legend. Sound system is perfect.",
         upvotes=41, timeAgo="20 min ago"),
    dict(id="ur5", clubName="ageHa", city="Tokyo", country="Japan",
         username="Shibuya_Nights", avatarUrl="https://i.pravatar.cc/150?img=44",
         tag="😎 Chill", vibeRating=4, comment="Good vibe, not too crowded yet. Perfect time to head in.",
         upvotes=12, timeAgo="35 min ago"),
    dict(id="ur6", clubName="ZERO Tokyo", city="Tokyo", country="Japan",
         username="TechnoJunkie_JP", avatarUrl="https://i.pravatar.cc/150?img=60",
         tag="🔥 Fire", vibeRating=5, comment="Oliver Heldens at ZERO — absolute banger set.",
         upvotes=56, timeAgo="2 min ago"),
    dict(id="ur7", clubName="fabric", city="London", country="United Kingdom",
         username="LondonNights_", avatarUrl="https://i.pravatar.cc/150?img=14",
         tag="🔥 Fire", vibeRating=5, comment="Vintage Culture all night long at fabric — queue was worth it.",
         upvotes=88, timeAgo="15 min ago"),
    dict(id="ur8", clubName="Printworks", city="London", country="United Kingdom",
         username="UK_Raver", avatarUrl="https://i.pravatar.cc/150?img=29",
         tag="🎵 Music Good", vibeRating=5, comment="Indira Paganotto was flawless. Printworks is stunning.",
         upvotes=63, timeAgo="28 min ago"),
    dict(id="ur9", clubName="Berghain", city="Berlin", country="Germany",
         username="BerlinTechno", avatarUrl="https://i.pravatar.cc/150?img=27",
         tag="😤 Packed", vibeRating=4, comment="Queue is 2 hours but inside is another world entirely.",
         upvotes=103, timeAgo="30 min ago"),
    dict(id="ur10", clubName="Tresor", city="Berlin", country="Germany",
         username="DarkFloor_DE", avatarUrl="https://i.pravatar.cc/150?img=36",
         tag="🔥 Fire", vibeRating=5, comment="Tresor basement is the darkest, loudest, best place on earth.",
         upvotes=77, timeAgo="18 min ago"),
    dict(id="ur11", clubName="LIV Miami", city="Miami", country="USA",
         username="MiamiVibes305", avatarUrl="https://i.pravatar.cc/150?img=41",
         tag="🔥 Fire", vibeRating=5, comment="Carl Cox at LIV is a religious experience.",
         upvotes=134, timeAgo="7 min ago"),
    dict(id="ur12", clubName="Exchange LA", city="Los Angeles", country="USA",
         username="LA_Clubber", avatarUrl="https://i.pravatar.cc/150?img=53",
         tag="😎 Chill", vibeRating=4, comment="Nicole Moudaber was incredible. Great rooftop.",
         upvotes=45, timeAgo="22 min ago"),
    dict(id="ur13", clubName="ELYSIUM", city="Bangkok", country="Thailand",
         username="BKK_Partylover", avatarUrl="https://i.pravatar.cc/150?img=39",
         tag="🎵 Music Good", vibeRating=4, comment="DJ Snake killed it! Bangkok nights are unreal.",
         upvotes=34, timeAgo="8 min ago"),
    dict(id="ur14", clubName="Marquee Singapore", city="Singapore", country="Singapore",
         username="SGNightlife", avatarUrl="https://i.pravatar.cc/150?img=51",
         tag="🚨 Packed", vibeRating=5, comment="Tiësto at Marquee. Insane atmosphere.",
         upvotes=72, timeAgo="4 min ago"),
    dict(id="ur15", clubName="Hï Ibiza", city="Ibiza", country="Spain",
         username="Ibiza_Forever", avatarUrl="https://i.pravatar.cc/150?img=63",
         tag="🔥 Fire", vibeRating=5, comment="ARTBAT + Hï Ibiza = legendary night. Unreal crowd.",
         upvotes=201, timeAgo="9 min ago"),
    dict(id="ur16", clubName="Octagon", city="Seoul", country="South Korea",
         username="SeoulNights", avatarUrl="https://i.pravatar.cc/150?img=57",
         tag="🔥 Fire", vibeRating=5, comment="Octagon is something else. Best club in Asia easily.",
         upvotes=89, timeAgo="12 min ago"),
    dict(id="ur17", clubName="Rex Club", city="Paris", country="France",
         username="ParisRaver", avatarUrl="https://i.pravatar.cc/150?img=17",
         tag="😎 Chill", vibeRating=5, comment="Amelie Lens + Rex Club = perfection. Sound system is insane.",
         upvotes=61, timeAgo="11 min ago"),
    dict(id="ur18", clubName="Chinese Laundry", city="Sydney", country="Australia",
         username="SydneyRaver", avatarUrl="https://i.pravatar.cc/150?img=48",
         tag="🎵 Music Good", vibeRating=4, comment="Skrillex going OFF in Sydney tonight 🔊",
         upvotes=55, timeAgo="16 min ago"),
    dict(id="ur19", clubName="WHITE Dubai", city="Dubai", country="UAE",
         username="DXBNights", avatarUrl="https://i.pravatar.cc/150?img=70",
         tag="🔥 Fire", vibeRating=5, comment="Marshmello was insane. Dubai always goes big.",
         upvotes=93, timeAgo="5 min ago"),
    dict(id="ur20", clubName="Green Valley", city="Camboriú", country="Brazil",
         username="BrazilBeats", avatarUrl="https://i.pravatar.cc/150?img=25",
         tag="🔥 Fire", vibeRating=5, comment="Green Valley lives up to the hype. INSANE open air.",
         upvotes=147, timeAgo="13 min ago"),
    dict(id="ur21", clubName="Shelter", city="Amsterdam", country="Netherlands",
         username="AMS_Techno", avatarUrl="https://i.pravatar.cc/150?img=32",
         tag="🎵 Music Good", vibeRating=5, comment="Ben Klock underground at Shelter. Nothing beats this.",
         upvotes=68, timeAgo="24 min ago"),
    dict(id="ur22", clubName="Kitty Su", city="Mumbai", country="India",
         username="MumbaiNights", avatarUrl="https://i.pravatar.cc/150?img=43",
         tag="😎 Chill", vibeRating=4, comment="DJ Nucleya bringing the bass hard tonight. Great crowd.",
         upvotes=31, timeAgo="19 min ago"),
]

# Real upcoming events (verified sources noted inline)
SOCIAL_EVENTS = [
    # Sri Lanka — Source: pickyourtrail.com, friday.lk
    dict(id="se1", title="Rooftop Sessions — Loft Lounge", clubName="Loft Lounge Bar",
         city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1571204829887-3b8d69e4094d?w=600",
         djName="DJ Nomad", date="Fri 23 May", time="9 PM – 3 AM",
         source="Facebook", popularityScore=81, isTrending=True),
    dict(id="se2", title="Saturday Skyline at ZAZA Bar", clubName="ZAZA Bar",
         city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         djName="DJ Kavish", date="Sat 24 May", time="8 PM – 2 AM",
         source="Instagram", popularityScore=73, isTrending=False),
    dict(id="se3", title="Colombo Rave Night", clubName="Clique Lounge Bar",
         city="Colombo", country="Sri Lanka",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         djName="DJ Lahiru b2b DJ Suranga", date="Sun 25 May", time="10 PM – 4 AM",
         source="Instagram", popularityScore=68, isTrending=False),

    # Japan — REAL events: World DJ Festival Jul 4-5, Porter Robinson Jul 8, ULTRA JAPAN 2026
    # Source: songkick.com/metro-areas/30717, nightlifetokyo.com
    dict(id="se4", title="World DJ Festival Japan 2026", clubName="WOMB",
         city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1598387180429-1a7d8d9e5e67?w=600",
         djName="Takkyu Ishino & Ken Ishii", date="Sat 4 Jul", time="11 PM – 6 AM",
         source="Resident Advisor", popularityScore=97, isTrending=True),
    dict(id="se5", title="Porter Robinson — Tokyo", clubName="ZERO Tokyo",
         city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
         djName="Porter Robinson", date="Wed 8 Jul", time="8 PM – 2 AM",
         source="Songkick", popularityScore=95, isTrending=True),
    dict(id="se6", title="ULTRA JAPAN 2026", clubName="ageHa",
         city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         djName="Multiple World-Class DJs", date="Sat 18 Jul", time="2 PM – 12 AM",
         source="Resident Advisor", popularityScore=99, isTrending=True),
    dict(id="se7", title="CIRCUS Tokyo Underground", clubName="CIRCUS Tokyo",
         city="Tokyo", country="Japan",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         djName="DJ Yuki", date="Fri 23 May", time="11 PM – 5 AM",
         source="Facebook", popularityScore=74, isTrending=False),

    # United Kingdom — REAL fabric London events (fabriclondon.com/whats-on, ra.co/clubs/237)
    # May 22: Vintage Culture | May 30: Raindance 2026 | Jun 12: Indira Paganotto | Jul 4: Ricardo Villalobos
    dict(id="se8", title="Raindance 2026 at fabric", clubName="fabric",
         city="London", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1574391884720-bbc3740c59d1?w=600",
         djName="DJ Brockie, Pete Cannon, Nookie + 30 more", date="Sat 30 May", time="11 PM – 7 AM",
         source="Resident Advisor", popularityScore=96, isTrending=True),
    dict(id="se9", title="fabric: Indira Paganotto", clubName="fabric",
         city="London", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600",
         djName="Indira Paganotto, Tommy Four Seven, Randomer", date="Fri 12 Jun", time="11 PM – 7 AM",
         source="Resident Advisor", popularityScore=91, isTrending=True),
    dict(id="se10", title="fabric: Ricardo Villalobos", clubName="fabric",
         city="London", country="United Kingdom",
         imageUrl="https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600",
         djName="Ricardo Villalobos, Sonja Moonear, Foehn & Jerome", date="Sat 4 Jul", time="11 PM – 7 AM",
         source="Resident Advisor", popularityScore=98, isTrending=True),

    # Germany — REAL Berghain events (berghain.berlin/en/program, ra.co/clubs/5031)
    # Jun 4: NUOVO TESTAMENTO | Jun 12: TIQ 16th Anniversary | Jun 17: Metzgertherapie 12 Years
    dict(id="se11", title="TIQ — 16th Anniversary", clubName="Berghain",
         city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1598387180429-1a7d8d9e5e67?w=600",
         djName="TIQ", date="Fri 12 Jun", time="12 AM – Open End",
         source="Resident Advisor", popularityScore=99, isTrending=True),
    dict(id="se12", title="Metzgertherapie — 12 Years", clubName="Berghain",
         city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         djName="Metzgertherapie", date="Tue 17 Jun", time="12 AM – Open End",
         source="Resident Advisor", popularityScore=95, isTrending=True),
    dict(id="se13", title="NUOVO TESTAMENTO at Berghain", clubName="Berghain",
         city="Berlin", country="Germany",
         imageUrl="https://images.unsplash.com/photo-1501527459-2d5409f8cf45?w=600",
         djName="NUOVO TESTAMENTO", date="Thu 4 Jun", time="11 PM – Open End",
         source="Resident Advisor", popularityScore=88, isTrending=False),

    # USA
    dict(id="se14", title="Carl Cox at LIV Miami", clubName="LIV Miami",
         city="Miami", country="USA",
         imageUrl="https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?w=600",
         djName="Carl Cox", date="Sat 24 May", time="10 PM – 8 AM",
         source="Resident Advisor", popularityScore=98, isTrending=True),
    dict(id="se15", title="Output: Dixon", clubName="Output",
         city="New York", country="USA",
         imageUrl="https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=600",
         djName="Dixon", date="Sat 24 May", time="10 PM – 6 AM",
         source="Resident Advisor", popularityScore=85, isTrending=False),
    dict(id="se16", title="Nicole Moudaber at Exchange", clubName="Exchange LA",
         city="Los Angeles", country="USA",
         imageUrl="https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600",
         djName="Nicole Moudaber", date="Fri 23 May", time="10 PM – 5 AM",
         source="Facebook", popularityScore=82, isTrending=False),

    # Thailand — REAL events: INAKOMA Hard Techno at Amnesia Bangkok
    # Source: phangan.events/bangkok, jetsetbangkok.com
    dict(id="se17", title="INAKOMA — Hard Techno Night", clubName="VOID",
         city="Bangkok", country="Thailand",
         imageUrl="https://images.unsplash.com/photo-1571204829887-3b8d69e4094d?w=600",
         djName="INAKOMA", date="Sat 24 May", time="10 PM – 6 AM",
         source="phangan.events", popularityScore=88, isTrending=True),
    dict(id="se18", title="ELYSIUM Presents: Festival Night", clubName="ELYSIUM",
         city="Bangkok", country="Thailand",
         imageUrl="https://images.unsplash.com/photo-1521337706264-a414f153a5f5?w=600",
         djName="DJ Snake", date="Fri 30 May", time="9 PM – 4 AM",
         source="Instagram", popularityScore=84, isTrending=True),

    # Singapore — Zouk 35th anniversary reopening (zoukgroup.com, thehoneycombers.com)
    dict(id="se19", title="Zouk 35th Anniversary Grand Reopening", clubName="Zouk Singapore",
         city="Singapore", country="Singapore",
         imageUrl="https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?w=600",
         djName="TBA — Massive lineup expected", date="Jun 2026 (TBC)", time="9 PM – 6 AM",
         source="Zouk Group", popularityScore=97, isTrending=True),
    dict(id="se20", title="Marquee: Tiësto", clubName="Marquee Singapore",
         city="Singapore", country="Singapore",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         djName="Tiësto", date="Sat 31 May", time="10 PM – 4 AM",
         source="Instagram", popularityScore=90, isTrending=True),

    # Spain — REAL Ibiza 2026 events (ticketsibiza.com, hiibiza.com)
    dict(id="se21", title="ARTBAT at Hï Ibiza", clubName="Hï Ibiza",
         city="Ibiza", country="Spain",
         imageUrl="https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600",
         djName="ARTBAT", date="Sat 24 May", time="12 AM – 8 AM",
         source="Resident Advisor", popularityScore=97, isTrending=True),
    dict(id="se22", title="Solomun +1 at Pacha", clubName="Pacha Ibiza",
         city="Ibiza", country="Spain",
         imageUrl="https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600",
         djName="Solomun", date="Sun 25 May", time="12 AM – 7 AM",
         source="Resident Advisor", popularityScore=96, isTrending=True),

    # France
    dict(id="se23", title="Nuit Sonores", clubName="Rex Club",
         city="Paris", country="France",
         imageUrl="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
         djName="Amelie Lens", date="Fri 23 May", time="11 PM – 6 AM",
         source="Resident Advisor", popularityScore=91, isTrending=True),
    dict(id="se24", title="ARTBAT at La Machine", clubName="La Machine du Moulin Rouge",
         city="Paris", country="France",
         imageUrl="https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600",
         djName="ARTBAT", date="Sat 31 May", time="11 PM – 7 AM",
         source="Resident Advisor", popularityScore=86, isTrending=False),

    # Australia
    dict(id="se25", title="Skrillex Sydney", clubName="Chinese Laundry",
         city="Sydney", country="Australia",
         imageUrl="https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600",
         djName="Skrillex", date="Sat 24 May", time="10 PM – 6 AM",
         source="Instagram", popularityScore=94, isTrending=True),
    dict(id="se26", title="Melbourne Deep Sessions", clubName="Stereo",
         city="Melbourne", country="Australia",
         imageUrl="https://images.unsplash.com/photo-1521337706264-a414f153a5f5?w=600",
         djName="Chris Liebing", date="Sun 25 May", time="10 PM – 5 AM",
         source="Facebook", popularityScore=77, isTrending=False),

    # South Korea
    dict(id="se27", title="Zedd at Octagon", clubName="Octagon",
         city="Seoul", country="South Korea",
         imageUrl="https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600",
         djName="Zedd", date="Sat 24 May", time="10 PM – 5 AM",
         source="Instagram", popularityScore=95, isTrending=True),

    # UAE
    dict(id="se28", title="Marshmello at WHITE Dubai", clubName="WHITE Dubai",
         city="Dubai", country="UAE",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         djName="Marshmello", date="Fri 23 May", time="11 PM – 5 AM",
         source="Instagram", popularityScore=91, isTrending=True),
    dict(id="se29", title="Armin van Buuren: Soho Garden", clubName="Soho Garden Dubai",
         city="Dubai", country="UAE",
         imageUrl="https://images.unsplash.com/photo-1516981442399-a91139e20ff8?w=600",
         djName="Armin van Buuren", date="Sat 31 May", time="10 PM – 4 AM",
         source="Facebook", popularityScore=87, isTrending=False),

    # Brazil
    dict(id="se30", title="Alesso: Green Valley", clubName="Green Valley",
         city="Camboriú", country="Brazil",
         imageUrl="https://images.unsplash.com/photo-1574391884720-bbc3740c59d1?w=600",
         djName="Alesso", date="Sat 24 May", time="10 PM – 6 AM",
         source="Instagram", popularityScore=93, isTrending=True),
    dict(id="se31", title="Richie Hawtin: D-Edge", clubName="D-Edge",
         city="São Paulo", country="Brazil",
         imageUrl="https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=600",
         djName="Richie Hawtin", date="Sat 31 May", time="12 AM – Open End",
         source="Resident Advisor", popularityScore=90, isTrending=True),

    # Netherlands
    dict(id="se32", title="Ben Klock: Shelter", clubName="Shelter",
         city="Amsterdam", country="Netherlands",
         imageUrl="https://images.unsplash.com/photo-1545128485-c400e7702796?w=600",
         djName="Ben Klock", date="Sat 24 May", time="11 PM – 8 AM",
         source="Resident Advisor", popularityScore=89, isTrending=True),
    dict(id="se33", title="Bicep: Paradiso", clubName="Paradiso",
         city="Amsterdam", country="Netherlands",
         imageUrl="https://images.unsplash.com/photo-1501527459-2d5409f8cf45?w=600",
         djName="Bicep (Live)", date="Sun 25 May", time="10 PM – 5 AM",
         source="Resident Advisor", popularityScore=84, isTrending=False),

    # India
    dict(id="se34", title="Nucleya Live: Kitty Su", clubName="Kitty Su",
         city="Mumbai", country="India",
         imageUrl="https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=600",
         djName="DJ Nucleya", date="Sat 24 May", time="10 PM – 4 AM",
         source="Instagram", popularityScore=79, isTrending=False),
]

# ── Seed functions ────────────────────────────────────────────────────────────

def clear_collection(col_name: str):
    col = db.collection(col_name)
    docs = col.stream()
    for doc in docs:
        doc.reference.delete()
    print(f"  Cleared {col_name}")

def seed_collection(col_name: str, items: list):
    col = db.collection(col_name)
    for item in items:
        doc_id = item.pop("id")
        # Remove None values
        item = {k: v for k, v in item.items() if v is not None}
        col.document(doc_id).set(item)
    print(f"  Seeded {len(items)} docs into {col_name}")

# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    clear = "--clear" in sys.argv
    print("Nightride - Live Hub Firestore Seed")
    print("=" * 40)

    if clear:
        print("Clearing existing data...")
        clear_collection("live_hub_clubs")
        clear_collection("live_hub_reports")
        clear_collection("live_hub_social")
        print()

    print("Seeding clubs...")
    seed_collection("live_hub_clubs", [dict(c) for c in CLUBS])

    print("Seeding user reports...")
    seed_collection("live_hub_reports", [dict(r) for r in REPORTS])

    print("Seeding social events...")
    seed_collection("live_hub_social", [dict(e) for e in SOCIAL_EVENTS])

    print()
    print("Done! Firestore Live Hub collections are ready.")
    print("   The Flutter app will stream updates in real-time.")
    print()
    print("To update a club's status later, edit the doc directly in")
    print("Firebase Console > live_hub_clubs > {club_id}")
    print("or call LiveHubService.updateClubStatus() from Dart.")
