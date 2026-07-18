import os
import json
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_document(text_content, filename, noise=True):
    # Create a white A4-ish page
    img = Image.new('RGB', (800, 1000), color=(250, 250, 245))
    d = ImageDraw.Draw(img)
    
    try:
        # Try to use a better default font if available on windows
        font = ImageFont.truetype("arial.ttf", 20)
        bold_font = ImageFont.truetype("arialbd.ttf", 24)
    except IOError:
        font = ImageFont.load_default()
        bold_font = ImageFont.load_default()

    y = 50
    for line in text_content.split('\n'):
        if line.startswith('## '):
            d.text((50, y), line[3:], fill=(0, 0, 0), font=bold_font)
            y += 40
        else:
            d.text((50, y), line, fill=(30, 30, 30), font=font)
            y += 25

    if noise:
        # Add a slight rotation for scan realism
        angle = random.uniform(-1.0, 1.0)
        img = img.rotate(angle, resample=Image.BICUBIC, fillcolor=(250, 250, 245))
        
        # Add slight blur
        img = img.filter(ImageFilter.GaussianBlur(radius=0.3))

    img.save(filename)

cases = []

# ==========================================
# CASE 1: Clean Control
# ==========================================
case_id = "case_1_clean"
c1_invoice = f"""## TAX INVOICE
Company: Acme Corp Supply
To: Sri Ram Textiles
GSTIN: 29ABCDE1234F1Z5
Date: 15-Sep-2023

Item: Cotton Fabric (1000 meters)
Amount: Rs. 150,000
Tax: Rs. 7,500
Total: Rs. 157,500"""

c1_gst = f"""## GST RETURN FILING (GSTR-3B)
Filing Period: Sep-2023
Taxpayer: Sri Ram Textiles
GSTIN: 29ABCDE1234F1Z5

Outward Supplies: Rs. 500,000
Inward Supplies: Rs. 150,000
Tax Paid: Rs. 7,500"""

c1_kyc = f"""## PERMANENT ACCOUNT NUMBER (PAN)
Name: Sri Ram Textiles
PAN: ABCDE1234F
DOB/Incorporation: 01-Jan-2015"""

c1_bank = f"""## BANK STATEMENT
Account: Sri Ram Textiles
Period: Sep 2023

01-Sep: Opening Balance  -- Rs. 500,000
05-Sep: NEFT Receipt (Sales) -- +Rs. 100,000
15-Sep: IMPS Transfer (Vendor) -- -Rs. 157,500
20-Sep: Salary Payouts -- -Rs. 50,000
30-Sep: Closing Balance -- Rs. 392,500"""

create_document(c1_invoice, f"{case_id}_invoice.png")
create_document(c1_gst, f"{case_id}_gst.png")
create_document(c1_kyc, f"{case_id}_kyc.png")
create_document(c1_bank, f"{case_id}_bank.png")

cases.append({
    "case_id": case_id,
    "description": "Clean control case. All signals pass.",
    "business_context": "Textile wholesaler, Bangalore, steady year-round demand.",
    "expected_signals": [],
    "documents": [f"{case_id}_invoice.png", f"{case_id}_gst.png", f"{case_id}_kyc.png", f"{case_id}_bank.png"]
})

# ==========================================
# CASE 2: GSTIN Mismatch
# ==========================================
case_id = "case_2_mismatch"
c2_invoice = f"""## TAX INVOICE
To: TechNova Electronics
GSTIN: 27XYZDE9999F1Z5
Date: 10-Oct-2023

Item: Microcontrollers
Amount: Rs. 200,000"""

c2_gst = f"""## GST RETURN FILING (GSTR-3B)
Taxpayer: TechNova Electronics
GSTIN: 27XYZDE9999F1Z5
Outward Supplies: Rs. 800,000"""

c2_kyc = f"""## PERMANENT ACCOUNT NUMBER (PAN)
Name: TechNova Electronics
PAN: WRONG9999F
(Notice this PAN doesn't match the middle 10 chars of the GSTIN)"""

c2_bank_lines = [f"{day:02d}-Oct: NEFT Receipt -- +Rs. {8900 + (day * 15)}" for day in range(1, 32)]
c2_bank = "## BANK STATEMENT\nAccount: TechNova Electronics\nPeriod: Oct 2023\n" + "\n".join(c2_bank_lines)

create_document(c2_invoice, f"{case_id}_invoice.png")
create_document(c2_gst, f"{case_id}_gst.png")
create_document(c2_kyc, f"{case_id}_kyc.png")
create_document(c2_bank, f"{case_id}_bank.png")

cases.append({
    "case_id": case_id,
    "description": "Deliberate GSTIN mismatch between invoice and KYC. Also skewed Benford's distribution.",
    "business_context": "Electronics supplier, Mumbai, high volume.",
    "expected_signals": ["entity_consistency", "benfords_law"],
    "documents": [f"{case_id}_invoice.png", f"{case_id}_gst.png", f"{case_id}_kyc.png", f"{case_id}_bank.png"]
})

# ==========================================
# CASE 3: Transaction Velocity Burst
# ==========================================
case_id = "case_3_velocity"
c3_invoice = "## TAX INVOICE\nTo: FastTrack FMCG\nGSTIN: 07AAACA1111A1Z1"
c3_gst = "## GST RETURN FILING\nGSTIN: 07AAACA1111A1Z1"
c3_kyc = "## PAN CARD\nPAN: AAACA1111A"
c3_bank = """## BANK STATEMENT
Account: FastTrack FMCG
Period: 12-Oct-2023 to 13-Oct-2023

12-Oct 10:01: IMPS TXN-1 -- -Rs. 49,999
12-Oct 10:05: IMPS TXN-2 -- -Rs. 49,999
12-Oct 10:11: IMPS TXN-3 -- -Rs. 49,999
12-Oct 10:15: IMPS TXN-4 -- -Rs. 49,999
12-Oct 10:20: IMPS TXN-5 -- -Rs. 49,999
12-Oct 10:25: IMPS TXN-6 -- -Rs. 49,999
12-Oct 10:30: IMPS TXN-7 -- -Rs. 49,999
12-Oct 10:35: IMPS TXN-8 -- -Rs. 49,999
12-Oct 10:40: IMPS TXN-9 -- -Rs. 49,999
12-Oct 10:45: IMPS TXN-10 -- -Rs. 49,999
12-Oct 10:50: IMPS TXN-11 -- -Rs. 49,999
12-Oct 10:55: IMPS TXN-12 -- -Rs. 49,999"""

create_document(c3_invoice, f"{case_id}_invoice.png")
create_document(c3_gst, f"{case_id}_gst.png")
create_document(c3_kyc, f"{case_id}_kyc.png")
create_document(c3_bank, f"{case_id}_bank.png")

cases.append({
    "case_id": case_id,
    "description": "Burst of near-identical transactions in a short window.",
    "business_context": "FMCG Distributor, Delhi, daily small restocks.",
    "expected_signals": ["transaction_velocity"],
    "documents": [f"{case_id}_invoice.png", f"{case_id}_gst.png", f"{case_id}_kyc.png", f"{case_id}_bank.png"]
})

# ==========================================
# CASE 4: Borderline / Median MAD
# ==========================================
case_id = "case_4_borderline"
c4_invoice = "## TAX INVOICE\nTo: GreenHarvest Agro\nGSTIN: 33BBBCB2222B2Z2"
c4_gst = "## GST RETURN FILING\nGSTIN: 33BBBCB2222B2Z2"
c4_kyc = "## PAN CARD\nPAN: BBBCB2222B"
c4_bank = """## BANK STATEMENT
Account: GreenHarvest Agro
Period: Nov 2023

01-Nov: Vendor Payout -- -Rs. 10,000
05-Nov: Vendor Payout -- -Rs. 11,500
10-Nov: Vendor Payout -- -Rs. 9,000
15-Nov: Vendor Payout -- -Rs. 10,500
20-Nov: Vendor Payout -- -Rs. 12,000
25-Nov: Seasonal Bulk Equip -- -Rs. 48,000
28-Nov: Vendor Payout -- -Rs. 9,500"""

create_document(c4_invoice, f"{case_id}_invoice.png")
create_document(c4_gst, f"{case_id}_gst.png")
create_document(c4_kyc, f"{case_id}_kyc.png")
create_document(c4_bank, f"{case_id}_bank.png")

cases.append({
    "case_id": case_id,
    "description": "Deliberately borderline case. Mild signal on one check (MAD outlier) meant to make Gemma express genuine moderate uncertainty given the context.",
    "business_context": "Seasonal Agro-exporter, Kerala, Q4 seasonal equipment buying expected.",
    "expected_signals": ["mad_outlier"],
    "documents": [f"{case_id}_invoice.png", f"{case_id}_gst.png", f"{case_id}_kyc.png", f"{case_id}_bank.png"]
})

# ==========================================
# CASE 5: Borderline Ambiguous
# ==========================================
case_id = "case_5_ambiguous"
c5_invoice = "## TAX INVOICE\nTo: Festival Retailers\nGSTIN: 44DDDDE3333C3Z3"
c5_gst = "## GST RETURN FILING\nGSTIN: 44DDDDE3333C3Z3"
c5_kyc = "## PAN CARD\nPAN: DDDDE3333C"
c5_bank = """## BANK STATEMENT
Account: Festival Retailers
Period: 01-Oct-2023 to 05-Oct-2023

01-Oct 11:00: IMPS TXN -- -Rs. 10,000
01-Oct 11:30: IMPS TXN -- -Rs. 10,000
01-Oct 12:00: IMPS TXN -- -Rs. 10,000
01-Oct 13:00: IMPS TXN -- -Rs. 10,000
01-Oct 14:00: IMPS TXN -- -Rs. 10,000
01-Oct 15:00: IMPS TXN -- -Rs. 10,000"""

create_document(c5_invoice, f"{case_id}_invoice.png")
create_document(c5_gst, f"{case_id}_gst.png")
create_document(c5_kyc, f"{case_id}_kyc.png")
create_document(c5_bank, f"{case_id}_bank.png")

cases.append({
    "case_id": case_id,
    "description": "Borderline Ambiguous case. Trips only one signal mildly (slightly elevated transaction velocity).",
    "business_context": "Seasonal retailer, mild transaction uptick expected in run-up to festival season.",
    "expected_signals": ["transaction_velocity"],
    "expected_confidence": "moderate",
    "documents": [f"{case_id}_invoice.png", f"{case_id}_gst.png", f"{case_id}_kyc.png", f"{case_id}_bank.png"]
})

with open("manifest.json", "w") as f:
    json.dump({"cases": cases}, f, indent=2)

print("Successfully generated synthetic sample documents and manifest.json.")
