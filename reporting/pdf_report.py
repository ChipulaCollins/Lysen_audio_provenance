"""
PDF Report Generator for Lysen Audio Provenance System using ReportLab.
Produces professional, human-readable audio provenance reports.
"""

import os
from typing import Dict, Any, Optional
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

def generate_pdf_report(manifest_dict: Dict[str, Any], output_path: str) -> None:
    """
    Generates a PDF provenance report from a manifest dictionary.
    """
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=0.5 * inch,
        leftMargin=0.5 * inch,
        topMargin=0.5 * inch,
        bottomMargin=0.5 * inch
    )

    styles = getSampleStyleSheet()

    # Custom palette
    PRIMARY = colors.HexColor("#1e293b")  # Dark slate
    SECONDARY = colors.HexColor("#0f766e") # Teal accent
    BG_LIGHT = colors.HexColor("#f8fafc")  # Light gray background
    TEXT_DARK = colors.HexColor("#334155")
    ACCENT_GREEN = colors.HexColor("#166534")

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=PRIMARY
    )

    subtitle_style = ParagraphStyle(
        "DocSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=14,
        textColor=SECONDARY
    )

    section_style = ParagraphStyle(
        "SectionHeader",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=16,
        textColor=PRIMARY,
        spaceBefore=10,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        "BodyTextCustom",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        textColor=TEXT_DARK
    )

    mono_style = ParagraphStyle(
        "MonoText",
        parent=styles["Normal"],
        fontName="Courier",
        fontSize=8,
        leading=10,
        textColor=PRIMARY
    )

    elements = []

    # Title & Header Banner
    elements.append(Paragraph("LYSEN AUDIO PROVENANCE REPORT", title_style))
    elements.append(Paragraph("LYSEN C2PA-COMPLIANT CRYPTOGRAPHIC VERIFICATION DOCUMENT", subtitle_style))
    elements.append(Spacer(1, 8))
    elements.append(HRFlowable(width="100%", thickness=1.5, color=SECONDARY, spaceBefore=2, spaceAfter=10))

    # Core Identifiers Table
    content = manifest_dict.get("content", {})
    metadata = manifest_dict.get("metadata", {})
    sig = manifest_dict.get("signature", {})
    canon = content.get("canonical_audio", {})
    tech = content.get("technical", {})
    loudness = tech.get("loudness", {})

    elements.append(Paragraph("1. Core Identifiers", section_style))
    
    id_data = [
        [Paragraph("<b>Manifest ID:</b>", body_style), Paragraph(manifest_dict.get("manifest_id", "N/A"), mono_style)],
        [Paragraph("<b>Content ID:</b>", body_style), Paragraph(content.get("content_id", "N/A"), mono_style)],
        [Paragraph("<b>File Hash (BLAKE3):</b>", body_style), Paragraph(content.get("file_hash", "N/A"), mono_style)],
        [Paragraph("<b>Acoustic ID:</b>", body_style), Paragraph(content.get("acoustic", {}).get("acoustic_id", "N/A"), mono_style)],
    ]

    t_id = Table(id_data, colWidths=[1.5 * inch, 6.0 * inch])
    t_id.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), BG_LIGHT),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#cbd5e1")),
        ("PADDING", (0, 0), (-1, -1), 5),
    ]))
    elements.append(t_id)
    elements.append(Spacer(1, 10))

    # Creation Metadata & Technical Specs Grid
    elements.append(Paragraph("2. Metadata & Technical Specifications", section_style))
    
    meta_tech_data = [
        [
            Paragraph("<b>Creator:</b> " + metadata.get("creator", "N/A"), body_style),
            Paragraph("<b>Sample Rate:</b> " + str(canon.get("sample_rate_hz", "N/A")) + " Hz", body_style)
        ],
        [
            Paragraph("<b>Client / Studio:</b> " + metadata.get("client", "N/A"), body_style),
            Paragraph("<b>Bit Depth:</b> " + str(canon.get("bit_depth", "N/A")) + "-bit PCM", body_style)
        ],
        [
            Paragraph("<b>Project Name:</b> " + metadata.get("project", "N/A"), body_style),
            Paragraph("<b>Channels:</b> " + str(canon.get("channels", "N/A")), body_style)
        ],
        [
            Paragraph("<b>Creation Timestamp:</b> " + metadata.get("creation_date", "N/A"), body_style),
            Paragraph("<b>Duration:</b> " + str(tech.get("duration_s", "N/A")) + " seconds", body_style)
        ],
        [
            Paragraph("<b>Software Chain:</b> " + ", ".join(metadata.get("software_chain", [])), body_style),
            Paragraph("<b>Loudness (EBU R128):</b> " + f"{loudness.get('integrated_lufs', 'N/A')} LUFS", body_style)
        ]
    ]

    t_meta = Table(meta_tech_data, colWidths=[3.75 * inch, 3.75 * inch])
    t_meta.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#cbd5e1")),
        ("PADDING", (0, 0), (-1, -1), 5),
    ]))
    elements.append(t_meta)
    elements.append(Spacer(1, 10))

    # Canonicalization Descriptor & Hashing Rule
    elements.append(Paragraph("3. Canonical Hashing Specification (Normative)", section_style))
    desc_text = canon.get("canonicalization_descriptor", "N/A")
    rule_text = canon.get("content_id_construction", "N/A")

    canon_data = [
        [Paragraph("<b>Canonical Descriptor:</b>", body_style)],
        [Paragraph(desc_text, mono_style)],
        [Paragraph("<b>Content ID Construction Rule:</b>", body_style)],
        [Paragraph(rule_text, mono_style)]
    ]
    t_canon = Table(canon_data, colWidths=[7.5 * inch])
    t_canon.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), BG_LIGHT),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#cbd5e1")),
        ("PADDING", (0, 0), (-1, -1), 5),
    ]))
    elements.append(t_canon)
    elements.append(Spacer(1, 10))

    # Cryptographic Signature Block
    elements.append(Paragraph("4. Cryptographic Signature", section_style))
    sig_data = [
        [Paragraph("<b>Algorithm:</b>", body_style), Paragraph(sig.get("algorithm", "N/A"), body_style)],
        [Paragraph("<b>Key ID:</b>", body_style), Paragraph(sig.get("key_id", "N/A"), mono_style)],
        [Paragraph("<b>Public Key:</b>", body_style), Paragraph(sig.get("public_key", "N/A"), mono_style)],
        [Paragraph("<b>Signature:</b>", body_style), Paragraph(sig.get("signature", "N/A"), mono_style)],
        [Paragraph("<b>Payload Canonicalization:</b>", body_style), Paragraph(sig.get("payload_c14n", "N/A"), body_style)],
        [Paragraph("<b>Signed Timestamp:</b>", body_style), Paragraph(sig.get("timestamp", "N/A"), body_style)],
    ]
    t_sig = Table(sig_data, colWidths=[2.0 * inch, 5.5 * inch])
    t_sig.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#e2e8f0")),
        ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#cbd5e1")),
        ("PADDING", (0, 0), (-1, -1), 4),
    ]))
    elements.append(t_sig)
    elements.append(Spacer(1, 10))

    # Verification Instructions & Trust Model
    elements.append(KeepTogether([
        Paragraph("5. Verification Instructions", section_style),
        Paragraph("• <b>Strict Mode:</b> Run <code>lysen verify --manifest manifest.json --audio input.wav</code> to verify bit-exact SHA3-256 content_id and BLAKE3 file_hash.", body_style),
        Paragraph("• <b>Acoustic Mode:</b> Compares Chromaprint acoustic_id fuzzy match if container audio is re-encoded.", body_style),
        Spacer(1, 6),
        HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#cbd5e1"), spaceBefore=4, spaceAfter=8),
        Paragraph("<i>Generated automatically by Lysen Audio Provenance Engine V1.0.0</i>", ParagraphStyle("Footer", parent=body_style, fontSize=8, textColor=colors.gray))
    ]))

    doc.build(elements)
