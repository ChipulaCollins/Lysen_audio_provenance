"""
3D Spatial Audio & Multichannel Canonicalization Engine (7.1.4, Ambisonics, ADM BWF).
"""

from typing import Dict, Any, List, Optional

SPATIAL_CHANNEL_MAPS = {
    12: {
        "spatial_format": "7.1.4",
        "channel_map": "L,R,C,LFE,Ls,Rs,Lb,Rb,Tfl,Tfr,Tbl,Tbr",
        "description": "7.1.4 Dolby Atmos / Multichannel Bed"
    },
    8: {
        "spatial_format": "7.1",
        "channel_map": "L,R,C,LFE,Ls,Rs,Lb,Rb",
        "description": "7.1 Surround"
    },
    6: {
        "spatial_format": "5.1",
        "channel_map": "L,R,C,LFE,Ls,Rs",
        "description": "5.1 Surround"
    },
    4: {
        "spatial_format": "Ambisonics_B_Format",
        "channel_map": "W,X,Y,Z",
        "description": "First Order Ambisonics 3D"
    }
}

def build_spatial_descriptor(bit_depth: int, sample_rate: int, channels: int) -> Dict[str, Any]:
    """
    Returns spatial canonicalization descriptor parameters for multi-channel / 3D audio tracks.
    """
    spatial_info = SPATIAL_CHANNEL_MAPS.get(channels, {
        "spatial_format": f"Multichannel_{channels}ch",
        "channel_map": ",".join(f"Ch{i+1}" for i in range(channels)),
        "description": f"{channels}-Channel Interleaved PCM"
    })

    descriptor_str = (
        f"format=pcm_int;endianness=le;interleaving=interleaved;"
        f"bit_depth={bit_depth};sample_rate={sample_rate};channels={channels};"
        f"spatial={spatial_info['spatial_format']};channel_map={spatial_info['channel_map']};"
        f"basis=decoded_pcm_bytes"
    )

    return {
        "canonical_descriptor": descriptor_str,
        "spatial_format": spatial_info["spatial_format"],
        "channel_map": spatial_info["channel_map"],
        "description": spatial_info["description"]
    }
