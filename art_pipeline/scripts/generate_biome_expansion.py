#!/usr/bin/env python3
"""Generate original biome art with a small, dependency-free pixel renderer."""
from pathlib import Path
import json
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "flutter_app" / "assets" / "images"
SIZE = (640, 360)


class PixelImage:
    def __init__(self, size, color=(0, 0, 0, 0)):
        self.width, self.height = size
        self.pixels = bytearray(self.width * self.height * 4)
        if color != (0, 0, 0, 0):
            for offset in range(0, len(self.pixels), 4):
                self.pixels[offset:offset + 4] = bytes(color)

    def load(self):
        return PixelAccess(self)

    def copy(self):
        copy = PixelImage((self.width, self.height))
        copy.pixels[:] = self.pixels
        return copy

    def alpha_composite(self, overlay, dest=(0, 0)):
        offset_x, offset_y = dest
        for y in range(overlay.height):
            target_y = y + offset_y
            if target_y < 0 or target_y >= self.height:
                continue
            for x in range(overlay.width):
                target_x = x + offset_x
                if target_x < 0 or target_x >= self.width:
                    continue
                source = (y * overlay.width + x) * 4
                if overlay.pixels[source + 3] == 0:
                    continue
                target = (target_y * self.width + target_x) * 4
                sa = overlay.pixels[source + 3] / 255
                da = self.pixels[target + 3] / 255
                oa = sa + da * (1 - sa)
                if oa <= 0:
                    continue
                for channel in range(3):
                    value = (
                        overlay.pixels[source + channel] * sa
                        + self.pixels[target + channel] * da * (1 - sa)
                    ) / oa
                    self.pixels[target + channel] = int(value + .5)
                self.pixels[target + 3] = int(oa * 255 + .5)

    def save(self, path, optimize=True):
        raw = bytearray()
        stride = self.width * 4
        for y in range(self.height):
            raw.append(0)
            raw.extend(self.pixels[y * stride:(y + 1) * stride])

        def chunk(kind, data):
            checksum = zlib.crc32(kind + data) & 0xffffffff
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)

        png = bytearray(b"\x89PNG\r\n\x1a\n")
        png.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", self.width,
                                               self.height, 8, 6, 0, 0, 0)))
        png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        png.extend(chunk(b"IEND", b""))
        Path(path).write_bytes(png)


class PixelAccess:
    def __init__(self, image):
        self.image = image

    def __setitem__(self, point, color):
        x, y = point
        if 0 <= x < self.image.width and 0 <= y < self.image.height:
            offset = (y * self.image.width + x) * 4
            self.image.pixels[offset:offset + 4] = bytes(color)


class PixelDraw:
    def __init__(self, image):
        self.image = image

    def _put(self, x, y, color):
        if 0 <= x < self.image.width and 0 <= y < self.image.height:
            offset = (y * self.image.width + x) * 4
            source_alpha = color[3] / 255
            if source_alpha <= 0:
                return
            destination_alpha = self.image.pixels[offset + 3] / 255
            if source_alpha >= 1 or destination_alpha <= 0:
                self.image.pixels[offset:offset + 4] = bytes(color)
                return
            output_alpha = source_alpha + destination_alpha * (1 - source_alpha)
            for channel in range(3):
                value = (
                    color[channel] * source_alpha
                    + self.image.pixels[offset + channel]
                    * destination_alpha * (1 - source_alpha)
                ) / output_alpha
                self.image.pixels[offset + channel] = int(value + .5)
            self.image.pixels[offset + 3] = int(output_alpha * 255 + .5)

    def rectangle(self, box, fill=None, outline=None, width=1):
        x0, y0, x1, y1 = [int(round(value)) for value in box]
        if fill is not None:
            for y in range(max(0, y0), min(self.image.height - 1, y1) + 1):
                for x in range(max(0, x0), min(self.image.width - 1, x1) + 1):
                    self._put(x, y, fill)
        if outline is not None:
            self.line([(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)],
                      fill=outline, width=width)

    def line(self, points, fill, width=1):
        if len(points) >= 4 and not isinstance(points[0], (tuple, list)):
            points = list(zip(points[::2], points[1::2]))
        else:
            points = list(points)
        radius = max(0, int(width) - 1) // 2
        for start, end in zip(points, points[1:]):
            x0, y0 = [int(round(value)) for value in start]
            x1, y1 = [int(round(value)) for value in end]
            dx, dy = abs(x1 - x0), abs(y1 - y0)
            sx = 1 if x0 < x1 else -1
            sy = 1 if y0 < y1 else -1
            error = dx - dy
            while True:
                for brush_y in range(-radius, radius + 1):
                    for brush_x in range(-radius, radius + 1):
                        self._put(x0 + brush_x, y0 + brush_y, fill)
                if x0 == x1 and y0 == y1:
                    break
                doubled = 2 * error
                if doubled > -dy:
                    error -= dy
                    x0 += sx
                if doubled < dx:
                    error += dx
                    y0 += sy

    def polygon(self, points, fill=None, outline=None):
        points = [(int(round(x)), int(round(y))) for x, y in points]
        if fill is not None and len(points) >= 3:
            min_y = max(0, min(y for _, y in points))
            max_y = min(self.image.height - 1, max(y for _, y in points))
            for y in range(min_y, max_y + 1):
                scan = y + .5
                intersections = []
                for index, (x1, y1) in enumerate(points):
                    x2, y2 = points[(index + 1) % len(points)]
                    if (y1 <= scan < y2) or (y2 <= scan < y1):
                        intersections.append(x1 + (scan - y1) * (x2 - x1) / (y2 - y1))
                intersections.sort()
                for pair in range(0, len(intersections) - 1, 2):
                    left = max(0, math.ceil(intersections[pair] - .5))
                    right = min(self.image.width - 1,
                                math.floor(intersections[pair + 1] - .5))
                    for x in range(left, right + 1):
                        self._put(x, y, fill)
        if outline is not None:
            self.line(points + [points[0]], outline)

    def ellipse(self, box, fill=None, outline=None, width=1):
        x0, y0, x1, y1 = [int(round(value)) for value in box]
        center_x, center_y = (x0 + x1) / 2, (y0 + y1) / 2
        radius_x, radius_y = max(.5, (x1 - x0) / 2), max(.5, (y1 - y0) / 2)
        if fill is not None:
            for y in range(max(0, y0), min(self.image.height - 1, y1) + 1):
                dy = (y - center_y) / radius_y
                if abs(dy) > 1:
                    continue
                span = radius_x * math.sqrt(1 - dy * dy)
                left = max(0, math.ceil(center_x - span))
                right = min(self.image.width - 1, math.floor(center_x + span))
                for x in range(left, right + 1):
                    self._put(x, y, fill)
        if outline is not None:
            steps = max(12, int(math.tau * max(radius_x, radius_y)))
            points = [
                (center_x + math.cos(i * math.tau / steps) * radius_x,
                 center_y + math.sin(i * math.tau / steps) * radius_y)
                for i in range(steps + 1)
            ]
            self.line(points, outline, width)

    def point(self, xy, fill):
        self._put(int(round(xy[0])), int(round(xy[1])), fill)


class Image:
    @staticmethod
    def new(mode, size, color=(0, 0, 0, 0)):
        if mode != "RGBA":
            raise ValueError("The biome generator writes RGBA PNG only.")
        return PixelImage(size, color)


class ImageDraw:
    @staticmethod
    def Draw(image):
        return PixelDraw(image)


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def inspect_png(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Invalid PNG signature: {path}")
    position = 8
    compressed = bytearray()
    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        kind = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        expected_crc = struct.unpack(
            ">I", data[position + 8 + length:position + 12 + length]
        )[0]
        actual_crc = zlib.crc32(kind + payload) & 0xffffffff
        if actual_crc != expected_crc:
            raise ValueError(f"PNG chunk CRC mismatch: {path}")
        if kind == b"IHDR":
            width, height, depth, color_type, *_ = struct.unpack(
                ">IIBBBBB", payload
            )
            if depth != 8 or color_type != 6:
                raise ValueError(f"Expected 8-bit RGBA PNG: {path}")
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break
        position += length + 12
    raw = zlib.decompress(compressed)
    stride = width * 4
    alpha_values = []
    for row in range(height):
        row_start = row * (stride + 1)
        if raw[row_start] != 0:
            raise ValueError(f"Unsupported PNG row filter in {path}")
        alpha_values.extend(raw[row_start + 4:row_start + 1 + stride:4])
    return width, height, min(alpha_values), max(alpha_values), len(data)


def rgba(color, alpha=255):
    return (*color, alpha)


def stepped_arch(draw, x, base, width, height, colors, alpha=235):
    dark, body, edge, light = colors
    crown = base - height
    # A squared, chipped arch with a deep open center.
    draw.polygon(
        [(x, base), (x, crown + 18), (x + 6, crown + 18),
         (x + 10, crown + 9), (x + width // 2, crown),
         (x + width - 10, crown + 9), (x + width - 6, crown + 18),
         (x + width, crown + 18), (x + width, base)],
        fill=rgba(body, alpha),
    )
    draw.polygon(
        [(x + 13, base), (x + 13, crown + 25), (x + 20, crown + 18),
         (x + width // 2, crown + 11), (x + width - 20, crown + 18),
         (x + width - 13, crown + 25), (x + width - 13, base)],
        fill=(11, 15, 22, 236),
    )
    draw.line(
        [(x + 4, base - 2), (x + 4, crown + 19), (x + 11, crown + 7),
         (x + width // 2, crown - 2), (x + width - 8, crown + 8)],
        fill=rgba(edge, alpha),
        width=3,
    )
    draw.rectangle((x - 5, base - 8, x + 5, base), fill=rgba(dark, alpha))
    draw.rectangle((x + width - 5, base - 8, x + width + 5, base),
                   fill=rgba(dark, alpha))
    draw.line((x + 12, crown + 29, x + 12, base - 12),
              fill=rgba(light, alpha * 2 // 3), width=2)


def desert_world():
    directory = OUT / "parallax" / "stage_02"
    rng = random.Random(20261109)
    dark = (43, 35, 37)
    stone = (102, 72, 52)
    edge = (168, 121, 75)
    light = (208, 165, 103)

    sky = Image.new("RGBA", SIZE)
    pixels = sky.load()
    for y in range(360):
        t = y / 359
        base = (13 + int(t * 19), 13 + int(t * 13), 22 + int(t * 7))
        for x in range(640):
            glow = max(0.0, 1.0 - math.sqrt(((x - 484) / 300) ** 2
                                            + ((y - 96) / 195) ** 2))
            pixels[x, y] = (
                min(255, base[0] + int(31 * glow)),
                min(255, base[1] + int(19 * glow)),
                min(255, base[2] + int(5 * glow)),
                255,
            )
    draw = ImageDraw.Draw(sky)
    draw.ellipse((426, 47, 518, 139), fill=(202, 139, 75, 27))
    draw.ellipse((449, 69, 495, 115), fill=(221, 176, 111, 38))
    # Distant wind-cut ridges; the center stays dark enough for the player.
    draw.polygon(
        [(0, 192), (46, 169), (96, 176), (151, 147), (210, 163),
         (270, 126), (329, 149), (386, 125), (434, 146), (488, 118),
         (542, 149), (594, 136), (639, 159), (639, 360), (0, 360)],
        fill=(36, 31, 34, 255),
    )
    draw.polygon(
        [(0, 230), (77, 195), (143, 210), (214, 178), (282, 203),
         (356, 166), (430, 199), (497, 163), (568, 187), (639, 170),
         (639, 360), (0, 360)],
        fill=(25, 23, 28, 255),
    )
    # Dune seams and the scattered grit catch only a little of the distant glow.
    for points in [
        [(0, 217), (71, 190), (142, 205), (205, 175)],
        [(260, 194), (344, 158), (420, 190), (492, 155)],
        [(495, 184), (557, 168), (639, 151)],
    ]:
        draw.line(points, fill=(119, 78, 53, 64), width=2)
    for _ in range(135):
        x, y = rng.randrange(640), rng.randrange(28, 284)
        a = rng.randrange(14, 62)
        draw.rectangle((x, y, x + rng.choice([0, 1, 2]), y),
                       fill=(202, 151, 96, a))
    save(sky, directory / "01_petroil_void.png")

    architecture = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(architecture)
    colors = (dark, stone, edge, light)
    # Receding galleries emerge from sand in broken, staggered silhouettes.
    for x, base, width, height in [
        (-30, 304, 146, 182), (106, 296, 112, 230),
        (284, 282, 132, 174), (505, 304, 154, 215),
    ]:
        stepped_arch(draw, x, base, width, height, colors, 183)
    for x, y, w in [(0, 205, 126), (172, 224, 112), (351, 195, 109),
                    (494, 229, 146)]:
        draw.polygon(
            [(x, y + 8), (x + 11, y), (x + w - 7, y + 2),
             (x + w, y + 10), (x + w - 4, y + 19), (x + 5, y + 17)],
            fill=(68, 51, 44, 212),
        )
        draw.line((x + 9, y + 2, x + w - 8, y + 4),
                  fill=(190, 139, 84, 182), width=2)
        for seam in range(x + 23, x + w - 7, 31):
            draw.line((seam, y + 10, seam + 4, y + 16),
                      fill=(35, 31, 34, 212), width=2)
    # Carved lintels and memory marks make the stone feel authored, not modular.
    for x, y in [(38, 132), (137, 97), (315, 143), (539, 123)]:
        draw.polygon(
            [(x, y + 18), (x + 15, y), (x + 31, y + 18),
             (x + 27, y + 23), (x + 15, y + 10), (x + 4, y + 23)],
            fill=(191, 142, 91, 96),
        )
        draw.line((x + 14, y + 19, x + 17, y + 35),
                  fill=(223, 180, 116, 100), width=2)
    # Sand-buried rubble softens the lower edges of the architecture.
    draw.polygon(
        [(0, 289), (42, 273), (81, 287), (120, 262), (169, 281),
         (205, 267), (258, 292), (308, 275), (360, 288), (419, 262),
         (473, 286), (530, 270), (582, 292), (639, 273), (639, 360),
         (0, 360)],
        fill=(43, 34, 33, 196),
    )
    save(architecture, directory / "02_suspended_galleries.png")

    near = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(near)
    # Edge-weighted debris and wind-bent desert plants frame the traversal.
    for points in [
        [(0, 360), (0, 294), (27, 280), (53, 291), (70, 270),
         (98, 302), (123, 288), (153, 310), (177, 360)],
        [(464, 360), (485, 311), (515, 295), (539, 309), (560, 278),
         (586, 301), (613, 276), (639, 291), (639, 360)],
    ]:
        draw.polygon(points, fill=(18, 19, 24, 238))
        draw.line(points[:5], fill=(116, 80, 54, 180), width=3)
    for x, y, lean in [(32, 282, -8), (91, 291, 9), (139, 305, -6),
                       (516, 294, 12), (578, 288, -10), (621, 291, 7)]:
        draw.line((x, y, x + lean // 2, y - 38),
                  fill=(124, 103, 61, 230), width=2)
        for i in range(4):
            yy = y - 9 - i * 7
            side = -1 if (i + x) % 2 else 1
            draw.polygon(
                [(x + lean // 2, yy), (x + lean // 2 + side * 9, yy - 7),
                 (x + lean // 2 + side * 6, yy + 1)],
                fill=(91, 107, 61, 218),
            )
    # A few old chain lengths still hang between the broken bridges.
    for x, top, length in [(206, 20, 104), (423, 4, 128)]:
        for i in range(length // 10):
            y = top + i * 10
            draw.rectangle((x, y, x + 2, y + 6), fill=(76, 65, 57, 190))
            draw.line((x - 2, y + 5, x + 4, y + 5),
                      fill=(146, 111, 75, 170), width=1)
    save(near, directory / "03_chains_and_windbreaks.png")

    haze = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(haze)
    for index in range(13):
        y = 56 + index * 21
        x = (index * 83) % 520 - 30
        alpha = 12 + (index % 4) * 5
        draw.polygon(
            [(x, y), (x + 94, y - 8), (x + 223, y - 5),
             (x + 141, y + 3), (x + 38, y + 5)],
            fill=(177, 126, 75, alpha),
        )
    for _ in range(90):
        x, y = rng.randrange(640), rng.randrange(30, 340)
        draw.rectangle((x, y, x + rng.choice([0, 1]), y),
                       fill=(222, 174, 112, rng.randrange(20, 76)))
    save(haze, directory / "04_wind_haze.png")

    study = sky.copy()
    study.alpha_composite(architecture)
    study.alpha_composite(near)
    study.alpha_composite(haze)
    save(study, directory / "stage_02_visual_study.png")


def forest_world():
    directory = OUT / "parallax" / "stage_03"
    rng = random.Random(3032026)
    dark = (22, 44, 35)
    stone = (49, 82, 60)
    edge = (101, 145, 91)
    light = (161, 185, 111)

    sky = Image.new("RGBA", SIZE)
    pixels = sky.load()
    for y in range(360):
        t = y / 359
        for x in range(640):
            glow = max(0.0, 1.0 - math.sqrt(((x - 322) / 235) ** 2
                                            + ((y - 61) / 195) ** 2))
            pixels[x, y] = (
                5 + int(t * 8) + int(24 * glow),
                14 + int(t * 14) + int(34 * glow),
                17 + int(t * 7) + int(13 * glow),
                255,
            )
    draw = ImageDraw.Draw(sky)
    # Canopy silhouettes leave a narrow, hopeful shaft of light over the tower.
    draw.polygon(
        [(0, 117), (27, 104), (44, 121), (64, 88), (83, 102),
         (107, 72), (133, 105), (158, 81), (189, 112), (217, 84),
         (246, 110), (278, 91), (298, 113), (318, 95), (344, 116),
         (372, 85), (401, 111), (427, 76), (457, 107), (484, 83),
         (516, 111), (544, 68), (572, 99), (603, 76), (640, 108),
         (640, 360), (0, 360)],
        fill=(15, 32, 25, 255),
    )
    draw.polygon(
        [(0, 211), (58, 192), (108, 203), (161, 177), (216, 200),
         (271, 181), (319, 204), (374, 174), (429, 196), (481, 169),
         (542, 193), (591, 174), (640, 190), (640, 360), (0, 360)],
        fill=(10, 25, 21, 255),
    )
    # Fine light shafts and a few pollen lights, kept behind the play plane.
    for x, width in [(106, 1), (190, 2), (446, 2), (531, 1)]:
        draw.polygon(
            [(x, 93), (x + width, 94), (x + 79, 314), (x + 48, 314)],
            fill=(115, 168, 98, 18),
        )
    for _ in range(100):
        x, y = rng.randrange(640), rng.randrange(36, 300)
        draw.rectangle((x, y, x, y), fill=(153, 193, 116, rng.randrange(18, 74)))
    save(sky, directory / "01_indigo_aperture.png")

    tower = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(tower)
    # Tree trunks embrace the old tower; stepped bark grooves give them scale.
    for x, width, top in [(-5, 72, 16), (77, 45, 58), (527, 54, 31),
                          (598, 68, 7)]:
        draw.polygon(
            [(x, 360), (x + 7, top + 28), (x + width // 2 - 8, top),
             (x + width // 2 + 9, top + 4), (x + width - 8, top + 41),
             (x + width, 360)],
            fill=(18, 43, 31, 232),
        )
        for offset in [12, width // 2, width - 14]:
            draw.line(
                [(x + offset, 340), (x + offset - 6, 235),
                 (x + offset + 3, 143), (x + offset - 5, top + 39)],
                fill=(61, 102, 66, 155), width=2,
            )
    # A soaring greenstone spire remains the landmark and narrative center.
    draw.polygon(
        [(203, 360), (214, 250), (232, 177), (254, 106), (285, 58),
         (314, 25), (342, 61), (372, 112), (393, 184), (414, 259),
         (430, 360)],
        fill=(33, 61, 46, 247),
    )
    draw.polygon(
        [(258, 360), (269, 246), (285, 174), (301, 110), (316, 79),
         (334, 114), (351, 180), (366, 250), (376, 360)],
        fill=(18, 39, 32, 252),
    )
    draw.line(
        [(218, 342), (231, 235), (252, 152), (287, 75), (314, 37)],
        fill=(87, 133, 77, 218), width=4,
    )
    draw.line(
        [(416, 340), (400, 233), (376, 149), (344, 76)],
        fill=(63, 109, 69, 191), width=3,
    )
    # Two pointed archive windows, softened by moss rather than shining glass.
    for x in [238, 370]:
        draw.polygon(
            [(x, 286), (x, 174), (x + 19, 135), (x + 38, 174), (x + 38, 286)],
            fill=(71, 105, 71, 241),
        )
        draw.polygon(
            [(x + 8, 277), (x + 8, 177), (x + 19, 151),
             (x + 30, 177), (x + 30, 277)],
            fill=(13, 29, 25, 255),
        )
        draw.line((x + 4, 238, x + 4, 190), fill=(145, 174, 100, 171), width=2)
        draw.line((x + 19, 164, x + 19, 267),
                  fill=(109, 157, 98, 107), width=2)
    # Roots clasp the foundation; amber is reserved for the preserved Lume mark.
    draw.polygon(
        [(178, 359), (228, 312), (276, 332), (317, 308), (365, 332),
         (415, 309), (462, 360)],
        fill=(27, 53, 37, 245),
    )
    draw.line([(213, 347), (264, 330), (292, 339)],
              fill=(102, 139, 79, 231), width=4)
    draw.line([(416, 349), (372, 330), (344, 339)],
              fill=(102, 139, 79, 231), width=4)
    draw.polygon(
        [(307, 68), (322, 49), (337, 68), (322, 89)],
        fill=(190, 157, 93, 205),
    )
    draw.polygon(
        [(315, 68), (322, 59), (329, 68), (322, 78)],
        fill=(191, 222, 144, 236),
    )
    # Moss ledges and hanging roots break up the masonry silhouette.
    for x, y in [(222, 188), (398, 228), (248, 291), (387, 304), (293, 117)]:
        draw.line((x, y, x + 38, y - 3), fill=(83, 132, 73, 216), width=3)
        for leaf in range(3):
            lx = x + 7 + leaf * 11
            draw.polygon(
                [(lx, y - 2), (lx + 4, y - 11), (lx + 8, y - 2)],
                fill=(101 + leaf * 7, 148 + leaf * 4, 78, 209),
            )
    save(tower, directory / "02_echo_tower.png")

    foreground = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(foreground)
    # Vines, small leaves and ferns frame the screen edges; the center stays open.
    for x, drift, length in [(14, 13, 174), (79, -8, 112),
                             (551, 9, 151), (625, -15, 194)]:
        points = []
        for step in range(10):
            y = step * length // 9
            points.append((x + int(math.sin(step * .7) * drift), y))
        draw.line(points, fill=(50, 94, 57, 225), width=3)
        for step in range(1, 10):
            lx, ly = points[step]
            side = -1 if step % 2 else 1
            draw.polygon(
                [(lx, ly), (lx + side * 13, ly + 4),
                 (lx + side * 8, ly + 10), (lx + side * 2, ly + 7)],
                fill=(76 + step % 3 * 8, 125 + step % 2 * 12, 69, 221),
            )
    for base_x, base_y, side in [(0, 360, 1), (112, 360, 1),
                                  (640, 360, -1), (531, 360, -1)]:
        for frond in range(5):
            start_x = base_x + side * frond * 7
            end_x = start_x + side * (24 + frond * 5)
            end_y = base_y - (38 + (frond % 3) * 12)
            draw.line((start_x, base_y, end_x, end_y),
                      fill=(61, 111, 62, 220), width=2)
            for leaf in range(4):
                t = (leaf + 1) / 5
                lx = int(start_x + (end_x - start_x) * t)
                ly = int(base_y + (end_y - base_y) * t)
                draw.polygon(
                    [(lx, ly), (lx + side * 13, ly - 9),
                     (lx + side * 11, ly + 1)],
                    fill=(79, 139, 72, 230),
                )
    # Tiny seed-glass motes echo the old stained glass without crowding play.
    for x, y in [(126, 115), (517, 92), (97, 239), (563, 209), (464, 139)]:
        draw.polygon(
            [(x, y - 5), (x + 4, y), (x, y + 6), (x - 4, y)],
            fill=(128, 181, 119, 154),
        )
        draw.point((x, y), fill=(203, 220, 150, 205))
    save(foreground, directory / "03_shattered_lancets.png")

    mist = Image.new("RGBA", SIZE)
    draw = ImageDraw.Draw(mist)
    for x, alpha in [(90, 17), (171, 12), (444, 15), (545, 11)]:
        draw.polygon(
            [(x, 0), (x + 5, 0), (x + 66, 310), (x + 38, 310)],
            fill=(105, 160, 103, alpha),
        )
    for index in range(10):
        y = 120 + index * 23
        x = (index * 103) % 560 - 32
        draw.polygon(
            [(x, y), (x + 102, y - 9), (x + 213, y - 5),
             (x + 128, y + 4), (x + 21, y + 5)],
            fill=(108, 151, 95, 12 + index % 3 * 4),
        )
    for _ in range(70):
        x, y = rng.randrange(640), rng.randrange(22, 334)
        draw.rectangle((x, y, x, y), fill=(172, 206, 125, rng.randrange(18, 72)))
    save(mist, directory / "04_silver_mist.png")

    study = sky.copy()
    study.alpha_composite(tower)
    study.alpha_composite(foreground)
    study.alpha_composite(mist)
    save(study, directory / "stage_03_visual_study.png")


def tile_atlas(stage, palette, forest=False):
    path = OUT / "tilesets" / f"{stage}_ruins_tiles.png"
    dark, stone, edge, light, accent = palette
    image = Image.new("RGBA", (256, 160))
    draw = ImageDraw.Draw(image)
    rng = random.Random(842 if forest else 237)
    for tile in range(40):
        x, y = (tile % 8) * 32, (tile // 8) * 32
        base = tuple(max(0, min(255, channel + rng.randrange(-5, 6)))
                     for channel in stone)
        draw.rectangle((x, y, x + 31, y + 31), fill=rgba(base))
        # A chipped, light-catching top plane reads clearly against the void.
        draw.line((x, y + 2, x + 31, y + 2), fill=rgba(edge), width=2)
        draw.line((x + 3, y + 5, x + 15, y + 5), fill=rgba(light, 190))
        if not forest:
            for band in range(3):
                yy = y + 10 + band * 7
                offset = rng.randrange(0, 8)
                draw.line((x + offset, yy, x + 11 + offset, yy - 1),
                          fill=rgba(dark, 230), width=2)
                draw.line((x + 16 + offset, yy + 1, x + 29, yy),
                          fill=rgba(edge, 176))
            draw.line(
                [(x + 7, y + 7), (x + 9, y + 13), (x + 5, y + 18),
                 (x + 10, y + 22), (x + 8, y + 28)],
                fill=rgba(dark, 222), width=2,
            )
            if tile % 5 == 1:
                draw.polygon(
                    [(x + 17, y + 8), (x + 24, y + 16),
                     (x + 17, y + 24), (x + 14, y + 16)],
                    outline=rgba(accent, 210),
                )
            for _ in range(13):
                px, py = x + rng.randrange(2, 30), y + rng.randrange(6, 30)
                draw.rectangle((px, py, px + rng.choice([0, 1]), py),
                               fill=rgba(light if _ % 3 == 0 else dark, 178))
        else:
            # Lichen flecks and rootlike joints make this a forest-grown stone.
            for band in range(3):
                yy = y + 10 + band * 8
                seam = x + (11 if (band + tile) % 2 else 23)
                draw.line((x + 3, yy, x + 28, yy), fill=rgba(dark, 222))
                draw.line((seam, yy, seam - 1, yy + 6), fill=rgba(dark, 218))
                draw.line((x + 4, yy + 1, x + 12, yy + 1),
                          fill=rgba(edge, 190))
            if tile % 4 in (0, 1):
                cx = x + 7 + (tile * 3) % 17
                draw.polygon(
                    [(cx, y + 25), (cx + 3, y + 15), (cx + 5, y + 20),
                     (cx + 9, y + 10), (cx + 11, y + 25)],
                    fill=rgba((66, 112, 62), 205),
                )
                draw.line((cx + 4, y + 25, cx + 7, y + 20),
                          fill=rgba(light, 174))
            for _ in range(17):
                px, py = x + rng.randrange(2, 30), y + rng.randrange(7, 31)
                color = accent if _ % 8 == 0 else edge if _ % 3 else dark
                draw.rectangle((px, py, px + rng.choice([0, 1]), py),
                               fill=rgba(color, 176))
        if tile % 7 == 3:
            # A small worn inscription is visible only on close inspection.
            draw.line((x + 19, y + 11, x + 21, y + 15),
                      fill=rgba(accent, 207), width=2)
            draw.line((x + 21, y + 15, x + 18, y + 20),
                      fill=rgba(accent, 207), width=2)
    save(image, path)
    (path.with_suffix(".json")).write_text(
        json.dumps(
            {
                "tile_size": [32, 32],
                "columns": 8,
                "rows": 5,
                "style": "mossbound_stone" if forest else "wind_cut_sandstone",
            },
            indent=2,
        ),
        encoding="utf-8",
    )


def background_creatures():
    worlds = OUT / "background_creatures" / "worlds"
    moth_sheet = Image.new("RGBA", (64 * 4, 48))
    for frame, wing_lift in enumerate([0, -5, 0, 5]):
        cell = Image.new("RGBA", (64, 48))
        draw = ImageDraw.Draw(cell)
        draw.polygon(
            [(30, 23), (17, 13 + wing_lift), (6, 18 + wing_lift),
             (13, 29), (28, 27)],
            fill=(143, 100, 61, 214),
        )
        draw.polygon(
            [(34, 23), (47, 13 + wing_lift), (58, 18 + wing_lift),
             (51, 29), (36, 27)],
            fill=(176, 133, 77, 215),
        )
        draw.line((30, 21, 32, 32), fill=(48, 38, 34, 245), width=3)
        draw.point((31, 19), fill=(228, 188, 117, 232))
        draw.line((30, 21, 24, 15 + wing_lift), fill=(205, 164, 103, 220))
        draw.line((34, 21, 40, 15 + wing_lift), fill=(205, 164, 103, 220))
        moth_sheet.alpha_composite(cell, (frame * 64, 0))
    save(moth_sheet, worlds / "dust_moth.png")

    crawler_sheet = Image.new("RGBA", (80 * 4, 40))
    for frame, step in enumerate([0, 1, 0, -1]):
        cell = Image.new("RGBA", (80, 40))
        draw = ImageDraw.Draw(cell)
        draw.polygon(
            [(8, 23), (20, 15), (40, 12), (62, 15), (73, 22),
             (61, 28), (34, 30), (17, 28)],
            fill=(76, 52, 40, 242),
        )
        draw.polygon(
            [(19, 18), (28, 12), (47, 12), (59, 18), (47, 22), (28, 22)],
            fill=(166, 112, 65, 237),
        )
        draw.line((20, 19, 57, 18), fill=(213, 162, 98, 228), width=2)
        for leg in range(5):
            x = 20 + leg * 9
            draw.line((x, 25, x - 4 + step, 32, x - 9 + step, 35),
                      fill=(112, 78, 51, 230), width=2)
        draw.point((66, 19), fill=(233, 197, 131, 255))
        crawler_sheet.alpha_composite(cell, (frame * 80, 0))
    save(crawler_sheet, worlds / "dune_crawler.png")

    wisp_sheet = Image.new("RGBA", (64 * 4, 80))
    for frame, sway in enumerate([0, 2, 0, -2]):
        cell = Image.new("RGBA", (64, 80))
        draw = ImageDraw.Draw(cell)
        draw.polygon(
            [(30 + sway, 8), (42 + sway, 22), (39 + sway, 43),
             (32 + sway, 65), (22 + sway, 44), (20 + sway, 23)],
            fill=(60, 111, 69, 164),
        )
        draw.polygon(
            [(31 + sway, 15), (37 + sway, 29), (32 + sway, 47),
             (27 + sway, 31)],
            fill=(163, 205, 125, 226),
        )
        for side in [-1, 1]:
            x = 30 + sway + side * 7
            draw.polygon(
                [(x, 35), (x + side * 12, 27), (x + side * 17, 36),
                 (x + side * 7, 41)],
                fill=(94, 151, 82, 188),
            )
            draw.line((x, 38, x + side * 4, 57),
                      fill=(74, 129, 70, 190), width=2)
        draw.ellipse((29 + sway, 28, 34 + sway, 33),
                     fill=(207, 230, 154, 222))
        draw.line((31 + sway, 64, 27 + sway, 73),
                  fill=(74, 123, 68, 140), width=2)
        draw.line((33 + sway, 64, 37 + sway, 73),
                  fill=(74, 123, 68, 140), width=2)
        wisp_sheet.alpha_composite(cell, (frame * 64, 0))
    save(wisp_sheet, worlds / "forest_wisp.png")

    colossus_sheet = Image.new("RGBA", (320 * 4, 144))
    for frame, sway in enumerate([0, 1, 0, -1]):
        cell = Image.new("RGBA", (320, 144))
        draw = ImageDraw.Draw(cell)
        draw.polygon(
            [(16, 74), (56, 39), (112, 25), (160, 39), (207, 26),
             (263, 42), (304, 68), (274, 89), (223, 102), (175, 96),
             (128, 111), (74, 101)],
            fill=(34, 30, 31, 221),
        )
        draw.polygon(
            [(40, 66), (85, 25 + sway * 3), (132, 17),
             (156, 32), (112, 45), (77, 70)],
            fill=(91, 62, 44, 222),
        )
        draw.polygon(
            [(165, 53), (216, 15 - sway * 3), (260, 27),
             (285, 55), (241, 48), (210, 67)],
            fill=(99, 67, 45, 218),
        )
        for leg in range(8):
            x = 71 + leg * 24
            draw.line(
                [(x, 88), (x - 12 + sway * 3, 113),
                 (x - 20 + sway * 4, 129 - leg % 3 * 4)],
                fill=(82, 62, 45, 228), width=3,
            )
        draw.line([(61, 74), (119, 60), (172, 71), (224, 62)],
                  fill=(157, 112, 67, 190), width=2)
        draw.rectangle((265, 61, 267, 62), fill=(227, 185, 111, 240))
        draw.rectangle((273, 62, 275, 63), fill=(227, 185, 111, 240))
        colossus_sheet.alpha_composite(cell, (frame * 320, 0))
    save(colossus_sheet, worlds / "sand_colossus.png")


def main():
    desert_world()
    forest_world()
    tile_atlas(
        "stage_02",
        ((45, 34, 31), (104, 73, 51), (168, 121, 75),
         (208, 165, 103), (226, 188, 127)),
    )
    tile_atlas(
        "stage_03",
        ((22, 44, 35), (49, 82, 60), (101, 145, 91),
         (161, 185, 111), (203, 190, 130)),
        forest=True,
    )
    background_creatures()
    print("Generated biome art:")
    assets = [
        OUT / "parallax/stage_02/01_petroil_void.png",
        OUT / "parallax/stage_02/02_suspended_galleries.png",
        OUT / "parallax/stage_02/03_chains_and_windbreaks.png",
        OUT / "parallax/stage_02/04_wind_haze.png",
        OUT / "parallax/stage_02/stage_02_visual_study.png",
        OUT / "parallax/stage_03/01_indigo_aperture.png",
        OUT / "parallax/stage_03/02_echo_tower.png",
        OUT / "parallax/stage_03/03_shattered_lancets.png",
        OUT / "parallax/stage_03/04_silver_mist.png",
        OUT / "parallax/stage_03/stage_03_visual_study.png",
        OUT / "tilesets/stage_02_ruins_tiles.png",
        OUT / "tilesets/stage_03_ruins_tiles.png",
        OUT / "background_creatures/worlds/dust_moth.png",
        OUT / "background_creatures/worlds/dune_crawler.png",
        OUT / "background_creatures/worlds/forest_wisp.png",
        OUT / "background_creatures/worlds/sand_colossus.png",
    ]
    for path in sorted(assets):
        width, height, alpha_min, alpha_max, byte_count = inspect_png(path)
        print(
            f"{path.relative_to(OUT)} {width}x{height} "
            f"alpha={alpha_min}..{alpha_max} size={byte_count}B"
        )
    for stage_id in ("stage_02", "stage_03"):
        level_path = ROOT / "flutter_app" / "assets" / "levels" / f"{stage_id}.json"
        level = json.loads(level_path.read_text(encoding="utf-8"))
        references = [level["tile_asset"]]
        references.extend(layer["asset"] for layer in level["layers"])
        missing = [asset for asset in references if not (OUT / asset).is_file()]
        if missing:
            raise FileNotFoundError(f"{stage_id} has missing art: {missing}")
        print(
            f"{stage_id}: {len(level['layers'])} parallax layers, "
            f"tile atlas present, {len(level['ambient_actors'])} ambient actors"
        )


if __name__ == "__main__":
    main()
