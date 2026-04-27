from datetime import date, timedelta
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether
)
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

OUTPUT = r"c:\Users\USER\Downloads\PartyApp\PartyApp\Nightride_Project_Timeline.pdf"
LOGO   = r"c:\Users\USER\Downloads\PartyApp\PartyApp\Nightride\assets\images\logo.png"

W, H = A4

# ── Dates ─────────────────────────────────────────────────────────────────────
START = date(2026, 4, 22)

def weeks(n): return timedelta(weeks=n)

p1_start = START
p1_end   = p1_start + weeks(2) - timedelta(days=1)
p2_start = p1_end + timedelta(days=1)
p2_end   = p2_start + weeks(2) - timedelta(days=1)
p3_start = p2_end + timedelta(days=1)
p3_end   = p3_start + weeks(2) - timedelta(days=1)
p4_start = p3_end + timedelta(days=1)
p4_end   = p4_start + weeks(2) - timedelta(days=1)
p5_start = p4_end + timedelta(days=1)
p5_end   = p5_start + weeks(1) - timedelta(days=1)

def fmt(d): return d.strftime("%d %b %Y")

# ── Palette (light / professional) ────────────────────────────────────────────
C_WHITE      = colors.HexColor("#FFFFFF")
C_BG         = colors.HexColor("#FFFFFF")
C_SURFACE    = colors.HexColor("#F7F8FA")
C_CARD       = colors.HexColor("#F0F2F7")
C_ACCENT     = colors.HexColor("#7C3AED")
C_ACCENT_LT  = colors.HexColor("#EDE9FE")
C_ACCENT2    = colors.HexColor("#5B21B6")
C_TEXT       = colors.HexColor("#111827")
C_TEXT2      = colors.HexColor("#374151")
C_GREY       = colors.HexColor("#6B7280")
C_MUTED      = colors.HexColor("#9CA3AF")
C_BORDER     = colors.HexColor("#E5E7EB")
C_BORDER2    = colors.HexColor("#D1D5DB")
C_GREEN      = colors.HexColor("#16A34A")
C_GREEN_BG   = colors.HexColor("#DCFCE7")
C_GREEN_TXT  = colors.HexColor("#14532D")
C_BLUE       = colors.HexColor("#2563EB")
C_BLUE_LT    = colors.HexColor("#DBEAFE")
C_CYAN       = colors.HexColor("#0891B2")
C_CYAN_LT    = colors.HexColor("#CFFAFE")
C_ORANGE     = colors.HexColor("#D97706")
C_ORANGE_LT  = colors.HexColor("#FEF3C7")
C_PURPLE_LT  = colors.HexColor("#F3F0FF")
C_HEADER_BG  = colors.HexColor("#FAFAFA")

def sty(name, **kw):
    base = dict(fontName="Helvetica", fontSize=9, textColor=C_TEXT,
                leading=13, spaceAfter=0, spaceBefore=0)
    base.update(kw)
    return ParagraphStyle(name, **base)

def P(text, style): return Paragraph(text, style)
def SP(h=3):        return Spacer(1, h * mm)

# ── Page canvas ───────────────────────────────────────────────────────────────
class PageDraw:
    def __call__(self, canv, doc):
        canv.saveState()

        # white page background
        canv.setFillColor(C_WHITE)
        canv.rect(0, 0, W, H, fill=1, stroke=0)

        # header band — very light grey
        canv.setFillColor(C_HEADER_BG)
        canv.rect(0, H - 42*mm, W, 42*mm, fill=1, stroke=0)

        # purple top bar
        canv.setFillColor(C_ACCENT)
        canv.rect(0, H - 3.5*mm, W, 3.5*mm, fill=1, stroke=0)

        # thin separator under header
        canv.setFillColor(C_BORDER)
        canv.rect(0, H - 42*mm, W, 0.5*mm, fill=1, stroke=0)

        # thin left accent rule (subtle)
        canv.setFillColor(C_ACCENT)
        canv.rect(0, 12*mm, 2.5*mm, H - 54*mm, fill=1, stroke=0)

        # logo
        logo_size = 23*mm
        canv.drawImage(LOGO, 9*mm, H - 40*mm, width=logo_size, height=logo_size,
                       preserveAspectRatio=True, mask='auto')

        # title
        canv.setFillColor(C_TEXT)
        canv.setFont("Helvetica-Bold", 22)
        canv.drawString(35*mm, H - 18*mm, "NIGHTRIDE")

        canv.setFillColor(C_GREY)
        canv.setFont("Helvetica", 10)
        canv.drawString(35*mm, H - 27*mm, "Project Timeline & Delivery Plan")

        # thin rule under subtitle
        canv.setStrokeColor(C_ACCENT)
        canv.setLineWidth(1.2)
        canv.line(35*mm, H - 29.5*mm, 100*mm, H - 29.5*mm)

        # meta right — dark text on light header
        canv.setFillColor(C_TEXT2)
        canv.setFont("Helvetica-Bold", 7.5)
        canv.drawRightString(W - 10*mm, H - 15*mm, f"Start Date:  {fmt(START)}")
        canv.drawRightString(W - 10*mm, H - 22.5*mm, f"Est. Completion:  {fmt(p5_end)}")
        canv.setFillColor(C_GREY)
        canv.setFont("Helvetica", 7.5)
        canv.drawRightString(W - 10*mm, H - 30*mm,
                             f"Prepared:  {date.today().strftime('%d %B %Y')}")

        # footer
        canv.setFillColor(C_SURFACE)
        canv.rect(0, 0, W, 12*mm, fill=1, stroke=0)
        canv.setFillColor(C_BORDER)
        canv.rect(0, 12*mm, W, 0.4*mm, fill=1, stroke=0)
        canv.setFillColor(C_GREY)
        canv.setFont("Helvetica", 7.5)
        canv.drawString(10*mm, 4.5*mm, "NIGHTRIDE  |  Project Timeline & Delivery Plan  |  Confidential")
        canv.setFillColor(C_ACCENT)
        canv.setFont("Helvetica-Bold", 7.5)
        canv.drawRightString(W - 10*mm, 4.5*mm, f"Page {doc.page}")

        canv.restoreState()

page_draw = PageDraw()

doc = SimpleDocTemplate(
    OUTPUT, pagesize=A4,
    leftMargin=10*mm, rightMargin=10*mm,
    topMargin=48*mm, bottomMargin=18*mm,
)

story = []

# ── EXECUTIVE SUMMARY ─────────────────────────────────────────────────────────
summary_text = (
    f"This document outlines the current development status of the <b>Nightride</b> mobile application "
    f"and provides a detailed delivery plan for all remaining phases. "
    f"Development begins on <b>{fmt(START)}</b> and is estimated to reach full production launch by "
    f"<b>{fmt(p5_end)}</b>. "
    f"The app is built using Flutter (iOS &amp; Android), Firebase, Mapbox and an AI-powered chat agent. "
    f"All completed work is live and testable on device today."
)
t = Table([[P(summary_text, sty("s", fontSize=8.5, textColor=C_TEXT2, leading=13))]],
          colWidths=[178*mm])
t.setStyle(TableStyle([
    ("BACKGROUND",   (0,0),(-1,-1), C_ACCENT_LT),
    ("LEFTPADDING",  (0,0),(-1,-1), 12),
    ("RIGHTPADDING", (0,0),(-1,-1), 12),
    ("TOPPADDING",   (0,0),(-1,-1), 9),
    ("BOTTOMPADDING",(0,0),(-1,-1), 9),
    ("LINEBEFORE",   (0,0),(0,-1),  3.5, C_ACCENT),
    ("BOX",          (0,0),(-1,-1), 0.5, C_BORDER2),
    ("ROUNDEDCORNERS", [3]),
]))
story.append(t)
story.append(SP(5))

# ── Section label style ───────────────────────────────────────────────────────
s_sec = sty("sec", fontSize=8, textColor=C_ACCENT2, fontName="Helvetica-Bold",
            letterSpacing=1.8, spaceBefore=4*mm, spaceAfter=2*mm)

# ── SECTION 1: COMPLETED ──────────────────────────────────────────────────────
story.append(P("01  /  COMPLETED — ALREADY DELIVERED", s_sec))

completed = [
    ("User Authentication",    "Sign Up, Sign In, Google Login, Forgot Password & OTP"),
    ("Onboarding Flow",        "Age, music taste, vibe, budget & social preferences"),
    ("Home Screen",            "Featured carousel, category rail & trending events"),
    ("Interactive Map",        "Mapbox with venue pins, cards & venue detail pages"),
    ("Search Screen",          "Real-time filtering across events and venues"),
    ("User Profile",           "View & edit — bio, interests, social links"),
    ("AI Chat Assistant",      "Live on server — event finder & night-out planner"),
    ("Badges & Rewards",       "Collection screen and badge claim flow"),
    ("Admin Panel",            "Add, edit & delete events — live in the app instantly"),
    ("Database Integration",   "Firebase Firestore — home screen pulls real events"),
    ("Design System",          "Dark theme, typography, components & navigation"),
]
for i, (feat, detail) in enumerate(completed):
    bg = C_WHITE if i % 2 == 0 else C_SURFACE
    row = Table([[
        P(f"<b>{feat}</b>",
          sty("cf", fontSize=8.5, textColor=C_TEXT, fontName="Helvetica-Bold")),
        P(detail, sty("cd", fontSize=8.5, textColor=C_GREY, leading=12)),
        P("<b>DONE</b>",
          sty("cs", fontSize=7.5, textColor=C_GREEN_TXT,
              fontName="Helvetica-Bold", alignment=TA_CENTER)),
    ]], colWidths=[54*mm, 104*mm, 20*mm])
    row.setStyle(TableStyle([
        ("BACKGROUND",    (0,0),(-1,-1), bg),
        ("BACKGROUND",    (2,0),(2,-1),  C_GREEN_BG),
        ("LEFTPADDING",   (0,0),(-1,-1), 8),
        ("RIGHTPADDING",  (0,0),(-1,-1), 6),
        ("TOPPADDING",    (0,0),(-1,-1), 5),
        ("BOTTOMPADDING", (0,0),(-1,-1), 5),
        ("LINEBEFORE",    (0,0),(0,-1),  3, C_GREEN),
        ("LINEBELOW",     (0,0),(-1,-1), 0.3, C_BORDER),
        ("VALIGN",        (0,0),(-1,-1), "MIDDLE"),
    ]))
    story.append(row)

story.append(SP(6))

# ── SECTION 2: PHASES ─────────────────────────────────────────────────────────
story.append(P("02  /  REMAINING PHASES — DETAILED BREAKDOWN", s_sec))

phases = [
    (
        "Phase 1", "Data & User Accounts", p1_start, p1_end, "2 Weeks", C_ACCENT, C_ACCENT_LT, C_PURPLE_LT,
        [
            ("Save User Profile to Database",
             "Bio, profile photo, city, age and all onboarding answers (vibe, genre, budget) saved to Firestore and loaded on login."),
            ("Role-Based Accounts",
             "Separate login and home screen for regular Users and Organizers. Organizer accounts have event management access."),
            ("Live Search from Database",
             "Search screen queries Firestore in real-time — events, venues and categories all searchable."),
            ("Real Venue Data on Map",
             "Replace test placeholder pins with real venue records from the database, including name, address and capacity."),
            ("Watchlist / Save Events",
             "Users can tap a heart to save events to their personal watchlist. Watching count updates live on event cards."),
        ]
    ),
    (
        "Phase 2", "Organizer Tools", p2_start, p2_end, "2 Weeks", C_BLUE, C_BLUE_LT, colors.HexColor("#EFF6FF"),
        [
            ("Organizer Dashboard",
             "Dedicated home screen for organizers showing all their events, status badges and quick action buttons."),
            ("Create & Publish Events",
             "Full event creation form — name, description, date, time, venue, cover image, genre, vibe, category and pricing."),
            ("Edit & Cancel Events",
             "Organizers can update or cancel any of their events. Status changes reflect instantly on user-facing screens."),
            ("Performers",
             "Link DJs, bands and comedians to events. Each performer has a name, bio and type tag displayed on the event page."),
            ("Event Policies",
             "Per-event rules — age restriction, refund policy, re-entry allowed, wheelchair accessibility and pet policy."),
        ]
    ),
    (
        "Phase 3", "Social & Reviews", p3_start, p3_end, "2 Weeks", C_CYAN, C_CYAN_LT, colors.HexColor("#F0FDFF"),
        [
            ("Ratings & Reviews",
             "Users submit a star rating (1–5) and written review after attending an event. Average rating shown on event page."),
            ("Organizer Replies",
             "Organizers can respond to individual reviews directly from their dashboard."),
            ("Social Posts",
             "Users upload photos or videos from events. Posts are tagged with location and linked to the event."),
            ("Likes & Comments",
             "Other users can like and comment on social posts. Interaction counts displayed on each post card."),
            ("Privacy Controls",
             "Post visibility set to public, friends-only or private. User social mode setting applies globally."),
        ]
    ),
    (
        "Phase 4", "Live Features & Notifications", p4_start, p4_end, "2 Weeks", C_ORANGE, C_ORANGE_LT, colors.HexColor("#FFFBEB"),
        [
            ("Live Event Metrics",
             "Real-time crowd size, current queue wait time and music type — updated by organizers or venue staff during the event."),
            ("Safety Alerts",
             "Push notifications sent to users near an event when crowd level or queue time crosses a threshold."),
            ("Settings Page",
             "Fully wired settings — notification preferences, privacy controls, profile visibility and app appearance toggle."),
        ]
    ),
    (
        "Phase 5", "Polish & Launch", p5_start, p5_end, "1 Week", C_GREEN, C_GREEN_BG, colors.HexColor("#F0FDF4"),
        [
            ("QA Testing",
             "End-to-end testing on physical Android and iOS devices covering all user flows, edge cases and regression checks."),
            ("Performance Optimisation",
             "Image caching, Firestore query optimisation, bundle size reduction and app startup time improvements."),
            ("App Store Submission",
             "Prepare store listings, screenshots and privacy policy. Submit to Google Play Store and Apple App Store for review."),
        ]
    ),
]

for tag, title, ps, pe, dur, col, col_lt, col_row, items in phases:
    block = []

    # phase header
    hdr = Table([[
        P(f"<b>{tag}</b>",
          sty("pt", fontSize=8, textColor=C_WHITE, fontName="Helvetica-Bold",
              alignment=TA_CENTER)),
        P(f"<b>{title}</b>",
          sty("pt2", fontSize=10, textColor=C_WHITE, fontName="Helvetica-Bold")),
        P(f"<b>{fmt(ps)}  \u2192  {fmt(pe)}</b>",
          sty("dt", fontSize=8, textColor=C_WHITE, fontName="Helvetica-Bold",
              alignment=TA_RIGHT)),
    ]], colWidths=[20*mm, 100*mm, 58*mm])
    hdr.setStyle(TableStyle([
        ("BACKGROUND",    (0,0),(-1,-1), col),
        ("LEFTPADDING",   (0,0),(-1,-1), 8),
        ("RIGHTPADDING",  (0,0),(-1,-1), 8),
        ("TOPPADDING",    (0,0),(-1,-1), 7),
        ("BOTTOMPADDING", (0,0),(-1,-1), 7),
        ("VALIGN",        (0,0),(-1,-1), "MIDDLE"),
    ]))
    block.append(hdr)

    # duration info row
    dur_row = Table([[
        P(f"Duration: <b>{dur}</b>  \u00a0|\u00a0  "
          f"Starts: <b>{fmt(ps)}</b>  \u00a0|\u00a0  "
          f"Delivers by: <b>{fmt(pe)}</b>",
          sty("dr", fontSize=8, textColor=C_TEXT2, leading=12)),
    ]], colWidths=[178*mm])
    dur_row.setStyle(TableStyle([
        ("BACKGROUND",   (0,0),(-1,-1), col_lt),
        ("LEFTPADDING",  (0,0),(-1,-1), 10),
        ("TOPPADDING",   (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("LINEBELOW",    (0,0),(-1,-1), 0.4, C_BORDER2),
    ]))
    block.append(dur_row)

    # deliverables
    for j, (task, desc) in enumerate(items):
        bg = C_WHITE if j % 2 == 0 else col_row
        item_row = Table([[
            P(f"<b>{task}</b>",
              sty("tk", fontSize=8.5, textColor=C_TEXT, fontName="Helvetica-Bold", leading=13)),
            P(desc, sty("ds", fontSize=8.5, textColor=C_GREY, leading=13)),
        ]], colWidths=[55*mm, 123*mm])
        item_row.setStyle(TableStyle([
            ("BACKGROUND",    (0,0),(-1,-1), bg),
            ("LEFTPADDING",   (0,0),(-1,-1), 10),
            ("RIGHTPADDING",  (0,0),(-1,-1), 8),
            ("TOPPADDING",    (0,0),(-1,-1), 5),
            ("BOTTOMPADDING", (0,0),(-1,-1), 5),
            ("LINEBEFORE",    (0,0),(0,-1),  2.5, col),
            ("LINEBELOW",     (0,0),(-1,-1), 0.3, C_BORDER),
            ("VALIGN",        (0,0),(-1,-1), "TOP"),
        ]))
        block.append(item_row)

    block.append(SP(5))
    story.append(KeepTogether(block))

# ── SECTION 3: MASTER SCHEDULE TABLE ─────────────────────────────────────────
story.append(P("03  /  MASTER SCHEDULE AT A GLANCE", s_sec))

s_th  = sty("th",  fontSize=8.5, textColor=C_WHITE,  fontName="Helvetica-Bold", alignment=TA_CENTER)
s_thl = sty("thl", fontSize=8.5, textColor=C_WHITE,  fontName="Helvetica-Bold")
s_td  = sty("td",  fontSize=8.5, textColor=C_TEXT2)
s_tdc = sty("tc",  fontSize=8.5, textColor=C_TEXT2,  alignment=TA_CENTER)
s_tot = sty("to",  fontSize=8.5, textColor=C_ACCENT2, fontName="Helvetica-Bold")
s_tc  = sty("tc2", fontSize=8.5, textColor=C_ACCENT2, fontName="Helvetica-Bold", alignment=TA_CENTER)
s_gn  = sty("gn",  fontSize=8,   textColor=C_GREEN_TXT, fontName="Helvetica-Bold", alignment=TA_CENTER)

tbl = [
    [P("PHASE", s_th), P("FOCUS AREA", s_thl), P("START", s_th),
     P("END", s_th), P("DURATION", s_th), P("STATUS", s_th)],

    [P("Completed", s_td),
     P("Auth, Home, Map, Search, Profile, AI Chat, Admin Panel", s_td),
     P("—", s_tdc), P("—", s_tdc), P("—", s_tdc),
     P("<b>DONE</b>", s_gn)],

    [P("Phase 1", s_td), P("Data & User Accounts", s_td),
     P(fmt(p1_start), s_tdc), P(fmt(p1_end), s_tdc), P("2 weeks", s_tdc),
     P("Upcoming", s_tdc)],

    [P("Phase 2", s_td), P("Organizer Tools", s_td),
     P(fmt(p2_start), s_tdc), P(fmt(p2_end), s_tdc), P("2 weeks", s_tdc),
     P("Upcoming", s_tdc)],

    [P("Phase 3", s_td), P("Social & Reviews", s_td),
     P(fmt(p3_start), s_tdc), P(fmt(p3_end), s_tdc), P("2 weeks", s_tdc),
     P("Upcoming", s_tdc)],

    [P("Phase 4", s_td), P("Live Features & Notifications", s_td),
     P(fmt(p4_start), s_tdc), P(fmt(p4_end), s_tdc), P("2 weeks", s_tdc),
     P("Upcoming", s_tdc)],

    [P("Phase 5", s_td), P("Polish & Launch", s_td),
     P(fmt(p5_start), s_tdc), P(fmt(p5_end), s_tdc), P("1 week", s_tdc),
     P("Upcoming", s_tdc)],

    [P("<b>TOTAL</b>", s_tot),
     P(f"<b>Full Production Launch — {fmt(p5_end)}</b>", s_tot),
     P(fmt(START), s_tc), P(fmt(p5_end), s_tc), P("<b>~9 weeks</b>", s_tc),
     P("", s_tdc)],
]

master = Table(tbl, colWidths=[22*mm, 66*mm, 24*mm, 24*mm, 20*mm, 22*mm], repeatRows=1)
master.setStyle(TableStyle([
    ("BACKGROUND",    (0,0),  (-1,0),  C_ACCENT),
    ("ROWBACKGROUNDS",(0,1),  (-1,-2), [C_WHITE, C_SURFACE]),
    ("BACKGROUND",    (0,1),  (-1,1),  C_GREEN_BG),
    ("BACKGROUND",    (5,1),  (5,1),   C_GREEN_BG),
    ("BACKGROUND",    (0,-1), (-1,-1), C_ACCENT_LT),
    ("LINEABOVE",     (0,-1), (-1,-1), 1.2, C_ACCENT),
    ("GRID",          (0,0),  (-1,-1), 0.4, C_BORDER),
    ("TOPPADDING",    (0,0),  (-1,-1), 5),
    ("BOTTOMPADDING", (0,0),  (-1,-1), 5),
    ("LEFTPADDING",   (0,0),  (-1,-1), 7),
    ("RIGHTPADDING",  (0,0),  (-1,-1), 7),
    ("VALIGN",        (0,0),  (-1,-1), "MIDDLE"),
]))
story.append(master)
story.append(SP(5))

# ── TERMS ─────────────────────────────────────────────────────────────────────
terms = (
    "<b>Terms &amp; Notes</b><br/>"
    "&#8226;  Each phase will be demonstrated and signed off by the client before the next phase begins.<br/>"
    "&#8226;  Timeline assumes uninterrupted, full-time development starting from the agreed start date.<br/>"
    "&#8226;  Any design revision requests or scope additions may affect the delivery dates shown above.<br/>"
    "&#8226;  Third-party delays such as App Store / Play Store review periods are outside the development timeline.<br/>"
    f"&#8226;  Estimated launch date: <b>{fmt(p5_end)}</b>"
)
terms_t = Table([[P(terms, sty("tr", fontSize=8, textColor=C_TEXT2, leading=14))]],
                colWidths=[178*mm])
terms_t.setStyle(TableStyle([
    ("BACKGROUND",   (0,0),(-1,-1), C_SURFACE),
    ("LEFTPADDING",  (0,0),(-1,-1), 12),
    ("RIGHTPADDING", (0,0),(-1,-1), 12),
    ("TOPPADDING",   (0,0),(-1,-1), 9),
    ("BOTTOMPADDING",(0,0),(-1,-1), 9),
    ("LINEBEFORE",   (0,0),(0,-1),  3.5, C_ORANGE),
    ("BOX",          (0,0),(-1,-1), 0.5, C_BORDER2),
]))
story.append(terms_t)

# ── Build ─────────────────────────────────────────────────────────────────────
doc.build(story, onFirstPage=page_draw, onLaterPages=page_draw)
print(f"PDF saved: {OUTPUT}")
