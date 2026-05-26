from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from datetime import date

OUTPUT = "Nightride_Infrastructure_Requirements.pdf"

# ── Colours ──────────────────────────────────────────────────────────────────
PURPLE      = colors.HexColor("#9F7AEA")
PURPLE_LIGHT= colors.HexColor("#EDE9FA")
DARK        = colors.HexColor("#2D3748")
MUTED       = colors.HexColor("#6B7280")
WHITE       = colors.white
ACCENT      = colors.HexColor("#ED64A6")
ROW_ALT     = colors.HexColor("#F8F7FF")

# ── Styles ───────────────────────────────────────────────────────────────────
base = getSampleStyleSheet()

def S(name, **kw):
    return ParagraphStyle(name, **kw)

title_style = S("DocTitle", fontSize=26, textColor=WHITE,
                fontName="Helvetica-Bold", alignment=TA_CENTER, leading=32)
subtitle_style = S("DocSub", fontSize=11, textColor=PURPLE_LIGHT,
                   fontName="Helvetica", alignment=TA_CENTER, leading=16)
h1 = S("H1", fontSize=15, textColor=PURPLE, fontName="Helvetica-Bold",
        spaceBefore=18, spaceAfter=6, leading=20)
h2 = S("H2", fontSize=12, textColor=DARK, fontName="Helvetica-Bold",
        spaceBefore=12, spaceAfter=4, leading=16)
body = S("Body", fontSize=10, textColor=DARK, fontName="Helvetica",
          leading=15, spaceAfter=4)
muted_body = S("Muted", fontSize=9, textColor=MUTED, fontName="Helvetica-Oblique",
                leading=13)
note = S("Note", fontSize=9, textColor=colors.HexColor("#7C3AED"),
          fontName="Helvetica-Oblique", leading=13,
          backColor=PURPLE_LIGHT, borderPadding=6)
code_style = S("Code", fontSize=8.5, textColor=DARK,
                fontName="Courier", leading=13,
                backColor=colors.HexColor("#F1F0FA"), borderPadding=5)

# ── Table style helpers ───────────────────────────────────────────────────────
def base_table(extra=None):
    s = [
        ("BACKGROUND",  (0,0), (-1,0), PURPLE),
        ("TEXTCOLOR",   (0,0), (-1,0), WHITE),
        ("FONTNAME",    (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTSIZE",    (0,0), (-1,0), 10),
        ("FONTNAME",    (0,1), (-1,-1), "Helvetica"),
        ("FONTSIZE",    (0,1), (-1,-1), 9.5),
        ("TEXTCOLOR",   (0,1), (-1,-1), DARK),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, ROW_ALT]),
        ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#E2E8F0")),
        ("TOPPADDING",  (0,0), (-1,-1), 7),
        ("BOTTOMPADDING",(0,0),(-1,-1), 7),
        ("LEFTPADDING", (0,0), (-1,-1), 10),
        ("RIGHTPADDING",(0,0), (-1,-1), 10),
        ("ROUNDEDCORNERS", [4]),
    ]
    if extra:
        s += extra
    return TableStyle(s)

# ── Document ──────────────────────────────────────────────────────────────────
doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=1.5*cm, bottomMargin=2*cm,
    title="Nightride Infrastructure Requirements",
    author="RISE AI Technical Team",
)

W = A4[0] - 4*cm   # usable width

story = []

# ── Cover banner ─────────────────────────────────────────────────────────────
banner_data = [[Paragraph("Nightride App", title_style)],
               [Paragraph("Infrastructure &amp; Server Requirements", subtitle_style)],
               [Paragraph(f"Prepared for: Nightride / RISE AI &nbsp;&nbsp;|&nbsp;&nbsp; Date: {date.today().strftime('%B %Y')}",
                          subtitle_style)]]
banner = Table(banner_data, colWidths=[W])
banner.setStyle(TableStyle([
    ("BACKGROUND", (0,0), (-1,-1), PURPLE),
    ("TOPPADDING",    (0,0), (-1,-1), 14),
    ("BOTTOMPADDING", (0,0), (-1,-1), 14),
    ("LEFTPADDING",   (0,0), (-1,-1), 10),
    ("ROUNDEDCORNERS", [8]),
]))
story.append(banner)
story.append(Spacer(1, 0.5*cm))

# ── 1. Overview ───────────────────────────────────────────────────────────────
story.append(Paragraph("1. Overview", h1))
story.append(Paragraph(
    "The Nightride platform consists of four components that require infrastructure planning:", body))
story.append(Spacer(1, 0.2*cm))

overview_data = [
    ["Component", "Type", "Hosting"],
    ["Mobile App (Flutter)", "iOS & Android", "App Store / Google Play"],
    ["AI Chat Backend (Python)", "Server", "VPS / Cloud — must purchase"],
    ["Web Admin Panel (Next.js)", "Web", "Firebase Hosting"],
    ["Database & Authentication", "Cloud", "Firebase (Google)"],
]
t = Table(overview_data, colWidths=[W*0.38, W*0.28, W*0.34])
t.setStyle(base_table([("FONTNAME",(2,2),(2,2),"Helvetica-Bold"),
                        ("TEXTCOLOR",(2,2),(2,2),ACCENT)]))
story.append(t)

# ── 2. Servers to Purchase ────────────────────────────────────────────────────
story.append(Paragraph("2. Servers to Purchase", h1))
story.append(Paragraph("2.1  AI Backend Server (Required)", h2))
story.append(Paragraph(
    "This is the core server that runs the Nightride AI chat agent. It processes all user "
    "messages, connects to Claude AI, and fetches live event data from Firestore.", body))
story.append(Spacer(1, 0.15*cm))
story.append(Paragraph("<b>Minimum Specifications:</b>", body))

specs_data = [
    ["CPU", "2 vCPU cores"],
    ["RAM", "4 GB"],
    ["Storage", "40 GB SSD"],
    ["OS", "Ubuntu 22.04 LTS"],
    ["Network", "1 Gbps / 3 TB monthly transfer"],
]
ts = Table(specs_data, colWidths=[W*0.3, W*0.7])
ts.setStyle(TableStyle([
    ("FONTNAME",    (0,0), (0,-1), "Helvetica-Bold"),
    ("FONTNAME",    (1,0), (1,-1), "Helvetica"),
    ("FONTSIZE",    (0,0), (-1,-1), 9.5),
    ("TEXTCOLOR",   (0,0), (-1,-1), DARK),
    ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, ROW_ALT]),
    ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#E2E8F0")),
    ("TOPPADDING",  (0,0), (-1,-1), 6),
    ("BOTTOMPADDING",(0,0),(-1,-1), 6),
    ("LEFTPADDING", (0,0), (-1,-1), 10),
]))
story.append(ts)
story.append(Spacer(1, 0.3*cm))
story.append(Paragraph("<b>Recommended Providers:</b>", body))

providers_data = [
    ["Provider", "Plan", "Monthly Cost", "Region"],
    ["Hetzner Cloud ★ Recommended", "CX22", "~$6 / €4.35", "EU Frankfurt"],
    ["DigitalOcean", "Basic Droplet", "~$24", "EU Amsterdam"],
    ["Google Cloud", "e2-medium", "~$25", "EU / Asia"],
    ["AWS EC2", "t3.medium", "~$30", "EU Frankfurt"],
]
tp = Table(providers_data, colWidths=[W*0.36, W*0.2, W*0.2, W*0.24])
tp.setStyle(base_table([
    ("TEXTCOLOR", (0,1),(0,1), PURPLE),
    ("FONTNAME",  (0,1),(0,1), "Helvetica-Bold"),
]))
story.append(tp)
story.append(Spacer(1, 0.2*cm))
story.append(Paragraph(
    "★  Recommendation: Hetzner CX22 — best value, enterprise-grade hardware, "
    "low latency to Dubai, London, Tokyo and Melbourne.", note))

story.append(Spacer(1, 0.3*cm))
story.append(Paragraph("2.2  Domain Name (Required)", h2))
story.append(Paragraph(
    "A custom domain is needed to point to the backend server (e.g. api.nightride.app).", body))

domain_data = [
    ["Provider", "Cost / Year", "Extras"],
    ["Cloudflare (Recommended)", "~$10", "Free DDoS protection + SSL"],
    ["Namecheap", "~$12", "Basic DNS management"],
]
td = Table(domain_data, colWidths=[W*0.38, W*0.2, W*0.42])
td.setStyle(base_table())
story.append(td)

# ── 3. Third-Party Services ───────────────────────────────────────────────────
story.append(Paragraph("3. Third-Party Services (Already Integrated)", h1))
story.append(Paragraph(
    "These services are cloud-based and already connected to the app. "
    "No additional server purchase is needed — costs are usage-based.", body))

services_data = [
    ["Service", "Purpose", "Est. Monthly Cost"],
    ["Firebase (Google)", "Database, Auth, Chat History", "$0–$50"],
    ["Anthropic Claude API", "AI chat brain (Claude Sonnet)", "$30–$100"],
    ["Ticketmaster API", "Live events — 18 countries", "Free tier / Commercial"],
    ["Mapbox", "Maps & location features", "$0–$25"],
]
tsv = Table(services_data, colWidths=[W*0.28, W*0.44, W*0.28])
tsv.setStyle(base_table())
story.append(tsv)

# ── 4. Monthly Cost Summary ───────────────────────────────────────────────────
story.append(Paragraph("4. Monthly Cost Summary", h1))
story.append(Paragraph("MVP / Startup Stage", h2))

mvp_data = [
    ["Item", "Cost / Month"],
    ["VPS Server (Hetzner CX22)", "$6"],
    ["Domain Name", "$1"],
    ["Anthropic Claude API", "$30–50"],
    ["Firebase (Blaze plan)", "$10–30"],
    ["Ticketmaster API", "Free"],
    ["Mapbox", "Free"],
    ["Total", "~$47–87 / month"],
]
tm = Table(mvp_data, colWidths=[W*0.7, W*0.3])
tm.setStyle(base_table([
    ("FONTNAME",  (0,-1),(-1,-1), "Helvetica-Bold"),
    ("BACKGROUND",(0,-1),(-1,-1), PURPLE_LIGHT),
    ("TEXTCOLOR", (0,-1),(-1,-1), PURPLE),
    ("FONTSIZE",  (0,-1),(-1,-1), 10),
]))
story.append(tm)
story.append(Spacer(1, 0.3*cm))
story.append(Paragraph("At Scale (10,000+ Active Users)", h2))

scale_data = [
    ["Item", "Cost / Month"],
    ["VPS Server (4 vCPU / 8 GB)", "$30–50"],
    ["Domain + SSL + CDN", "$5"],
    ["Anthropic Claude API", "$150–300"],
    ["Firebase (Blaze plan)", "$50–150"],
    ["Ticketmaster Commercial License", "TBD"],
    ["Mapbox", "$25–100"],
    ["Total", "~$260–600 / month"],
]
tsc = Table(scale_data, colWidths=[W*0.7, W*0.3])
tsc.setStyle(base_table([
    ("FONTNAME",  (0,-1),(-1,-1), "Helvetica-Bold"),
    ("BACKGROUND",(0,-1),(-1,-1), PURPLE_LIGHT),
    ("TEXTCOLOR", (0,-1),(-1,-1), PURPLE),
    ("FONTSIZE",  (0,-1),(-1,-1), 10),
]))
story.append(tsc)

# ── 5. Target Markets ─────────────────────────────────────────────────────────
story.append(Paragraph("5. Target Markets", h1))

markets_data = [
    ["City", "Country", "Ticketmaster Coverage"],
    ["Dubai",     "UAE",       "Yes (AE)"],
    ["Tokyo",     "Japan",     "Yes (JP)"],
    ["London",    "UK",        "Yes (GB)"],
    ["Melbourne", "Australia", "Yes (AU)"],
]
tmk = Table(markets_data, colWidths=[W*0.3, W*0.35, W*0.35])
tmk.setStyle(base_table())
story.append(tmk)

# ── 6. Architecture ───────────────────────────────────────────────────────────
story.append(Paragraph("6. Deployment Architecture", h1))
arch = (
    "Mobile App (iOS / Android)\n"
    "        │  HTTPS\n"
    "        ▼\n"
    "VPS Backend Server  ──►  Anthropic Claude API  (AI brain)\n"
    "(FastAPI + Agent)   ──►  Firebase Firestore     (database)\n"
    "                    ──►  Ticketmaster API        (live events)"
)
story.append(Paragraph(arch.replace("\n", "<br/>"), code_style))

# ── 7. Next Steps ─────────────────────────────────────────────────────────────
story.append(Paragraph("7. Immediate Next Steps", h1))

steps_data = [
    ["#", "Action", "Priority"],
    ["1", "Purchase VPS — Hetzner CX22 or DigitalOcean Droplet", "High"],
    ["2", "Register domain via Cloudflare", "High"],
    ["3", "Deploy backend to VPS (Nightride/Agent/ folder)", "High"],
    ["4", "Update Flutter app BACKEND_URL to new domain", "High"],
    ["5", "Upgrade Firebase to Blaze plan before launch", "Medium"],
    ["6", "Apply for Ticketmaster commercial API license", "Medium"],
]
tsteps = Table(steps_data, colWidths=[W*0.06, W*0.72, W*0.22])
tsteps.setStyle(base_table([
    ("TEXTCOLOR", (2,1),(2,2), colors.HexColor("#C53030")),
    ("TEXTCOLOR", (2,3),(2,4), colors.HexColor("#C53030")),
    ("TEXTCOLOR", (2,5),(2,6), colors.HexColor("#B7791F")),
    ("FONTNAME",  (2,1),(2,-1), "Helvetica-Bold"),
]))
story.append(tsteps)

# ── Footer ────────────────────────────────────────────────────────────────────
story.append(Spacer(1, 0.8*cm))
story.append(HRFlowable(width=W, thickness=0.5, color=PURPLE_LIGHT))
story.append(Spacer(1, 0.2*cm))
story.append(Paragraph(
    "Document prepared by RISE AI Technical Team  •  Nightride Platform  •  Confidential",
    S("Footer", fontSize=8, textColor=MUTED, fontName="Helvetica", alignment=TA_CENTER)))

# ── Build ─────────────────────────────────────────────────────────────────────
doc.build(story)
print(f"PDF saved: {OUTPUT}")
