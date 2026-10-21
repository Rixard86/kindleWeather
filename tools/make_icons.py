import math
import pathlib

ICON_DIR = pathlib.Path(__file__).resolve().parent.parent / "weatherscreen.koplugin" / "icons"
CANVAS = 64
FULL_TURN = 360
HALF_TURN = 180
OUTLINE = 'stroke="#000" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"'
FINE_LINE = 'stroke="#000" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"'
WHITE = "#FFFFFF"
LIGHT = "#E0E0E0"
MID = "#BDBDBD"
DARK = "#8C8C8C"
BLUSH = "#D0D0D0"
CLOUD_CIRCLES = [(17, 39, 9), (30, 29, 13), (45, 32, 10), (50, 40, 8)]
CLOUD_FACE_CENTER = (33, 35.5)
SUN_CENTER = (32, 32)
EYE_SPREAD = 6.5
EYE_RADIUS = 2.5
BLUSH_SPREAD = 11
CRESCENT = "M29.41 14.02A20 20 0 1 0 49.37 38.96A16 16 0 0 1 29.41 14.02Z"
RAISED_CLOUD = (0, -7)
HORIZON_SUN_CENTER = (32, 42)
MIST_BANDS = [(7, 43, 43.5), (19, 57, 51), (11, 37, 58.5)]
FOG_CLOUD = (0, -11)
DETAIL_OUTLINE_WIDTH = "1.8"
THUNDER_CLOUD = (0, -11)


def point_on(circle, degrees):
    center_x, center_y, radius = circle
    angle = math.radians(degrees)
    return center_x + radius * math.cos(angle), center_y + radius * math.sin(angle)


def angle_of(circle, point):
    return math.degrees(math.atan2(point[1] - circle[1], point[0] - circle[0])) % FULL_TURN


def upper_intersection(first, second):
    (x1, y1, r1), (x2, y2, r2) = first, second
    distance = math.hypot(x2 - x1, y2 - y1)
    along = (r1 * r1 - r2 * r2 + distance * distance) / (2 * distance)
    height = math.sqrt(r1 * r1 - along * along)
    base_x, base_y = x1 + along * (x2 - x1) / distance, y1 + along * (y2 - y1) / distance
    offset_x, offset_y = height * (y2 - y1) / distance, height * (x2 - x1) / distance
    candidates = [(base_x + offset_x, base_y - offset_y), (base_x - offset_x, base_y + offset_y)]
    return min(candidates, key=lambda point: point[1])


def clockwise_arc(circle, span):
    start, end = span
    sweep = (angle_of(circle, end) - angle_of(circle, start)) % FULL_TURN
    large = 1 if sweep > HALF_TURN else 0
    return f"A{circle[2]} {circle[2]} 0 {large} 1 {end[0]:.2f} {end[1]:.2f}"


def cloud_path():
    bottom_angle = 90
    start = point_on(CLOUD_CIRCLES[0], bottom_angle)
    points = [start]
    for first, second in zip(CLOUD_CIRCLES, CLOUD_CIRCLES[1:]):
        points.append(upper_intersection(first, second))
    points.append(point_on(CLOUD_CIRCLES[-1], bottom_angle))
    arcs = [clockwise_arc(circle, (points[index], points[index + 1])) for index, circle in enumerate(CLOUD_CIRCLES)]
    return f"M{start[0]:.2f} {start[1]:.2f}" + "".join(arcs) + "Z"


def eyes(center, mood):
    left, right, y = center[0] - EYE_SPREAD, center[0] + EYE_SPREAD, center[1]
    if mood == "sleepy":
        return f'<path d="M{left - 2.6} {y} q2.6 2.2 5.2 0M{right - 2.6} {y} q2.6 2.2 5.2 0" fill="none" {FINE_LINE}/>'
    return (f'<circle cx="{left}" cy="{y}" r="{EYE_RADIUS}" fill="#000"/>'
            f'<circle cx="{right}" cy="{y}" r="{EYE_RADIUS}" fill="#000"/>')


def mouth(center, mood):
    x, y = center[0], center[1] + 4
    curve = "q3.5 -3 7 0" if mood in ("sad", "angry") else "q3.5 3.4 7 0"
    shift = 1.2 if mood in ("sad", "angry") else 0
    return f'<path d="M{x - 3.5} {y + shift} {curve}" fill="none" {FINE_LINE}/>'


def brows(center, mood):
    left, right, y = center[0] - EYE_SPREAD, center[0] + EYE_SPREAD, center[1] - 4
    if mood == "sad":
        return f'<path d="M{left - 2.5} {y + 0.8} l4.5 -1.6M{right + 2.5} {y + 0.8} l-4.5 -1.6" {FINE_LINE}/>'
    if mood == "angry":
        return f'<path d="M{left - 2.5} {y - 1} l4.5 2M{right + 2.5} {y - 1} l-4.5 2" {FINE_LINE}/>'
    return ""


def blush(center):
    y = center[1] + 3.2
    return "".join(f'<ellipse cx="{center[0] + side * BLUSH_SPREAD}" cy="{y}" rx="3.2" ry="2" fill="{BLUSH}"/>'
                   for side in (-1, 1))


def face(center, mood):
    cheeks = "" if mood in ("sad", "angry") else blush(center)
    return cheeks + eyes(center, mood) + brows(center, mood) + mouth(center, mood)


def cloud(look, offset):
    fill, mood = look
    content = f'<path d="{cloud_path()}" fill="{fill}" {OUTLINE}/>'
    if mood:
        content += face(CLOUD_FACE_CENTER, mood)
    return f'<g transform="translate({offset[0]} {offset[1]})">{content}</g>'


def rays(center, spokes):
    (inner, outer), angles = spokes
    segments = []
    for degrees in angles:
        start = point_on((center[0], center[1], inner), degrees)
        end = point_on((center[0], center[1], outer), degrees)
        segments.append(f"M{start[0]:.2f} {start[1]:.2f}L{end[0]:.2f} {end[1]:.2f}")
    return f'<path d="{"".join(segments)}" fill="none" {OUTLINE}/>'


def sun():
    body = f'<circle cx="{SUN_CENTER[0]}" cy="{SUN_CENTER[1]}" r="13" fill="{LIGHT}" {OUTLINE}/>'
    return rays(SUN_CENTER, ((19, 26), range(0, FULL_TURN, 45))) + body + face((32, 30.5), "happy")


def small_sun():
    center = (21, 21)
    body = f'<circle cx="{center[0]}" cy="{center[1]}" r="9.5" fill="{LIGHT}" {OUTLINE}/>'
    return rays(center, ((14, 19), (135, 180, 225, 270, 315))) + body


def star(center, size):
    points = []
    for index in range(10):
        radius = size if index % 2 == 0 else size * 0.45
        points.append(point_on((center[0], center[1], radius), index * 36 - 90))
    path = "M" + "L".join(f"{x:.2f} {y:.2f}" for x, y in points) + "Z"
    return f'<path d="{path}" fill="{LIGHT}" stroke="#000" stroke-width="{DETAIL_OUTLINE_WIDTH}" stroke-linejoin="round"/>'


def moon(transform):
    return (f'<path transform="{transform}" d="{CRESCENT}" fill="{LIGHT}" '
            f'stroke="#000" stroke-width="{3.5 / moon_scale(transform):.2f}" stroke-linejoin="round"/>')


def moon_scale(transform):
    return float(transform.split("scale(")[1].rstrip(")")) if "scale(" in transform else 1.0


def drop(center, size):
    x, y = center
    path = (f"M{x} {y - size}C{x + size * 0.7} {y - size * 0.1} {x + size * 0.7} {y + size * 0.6} {x} {y + size * 0.6}"
            f"C{x - size * 0.7} {y + size * 0.6} {x - size * 0.7} {y - size * 0.1} {x} {y - size}Z")
    return f'<path d="{path}" fill="{MID}" stroke="#000" stroke-width="{DETAIL_OUTLINE_WIDTH}" stroke-linejoin="round"/>'


def snowflake(center):
    arms = rays(center, ((0, 4.2), (30, 90, 150, 210, 270, 330)))
    return arms.replace(OUTLINE, FINE_LINE)


def mist_band(band):
    start_x, end_x, center_y = band
    height = 5
    return (f'<rect x="{start_x}" y="{center_y - height / 2}" width="{end_x - start_x}" height="{height}" '
            f'rx="{height / 2}" fill="{LIGHT}" {OUTLINE.replace("3.5", DETAIL_OUTLINE_WIDTH)}/>')


def mist():
    return "".join(mist_band(band) for band in MIST_BANDS)


def horizon_sun(rising):
    center = HORIZON_SUN_CENTER
    half_disc = (f'<path d="M{center[0] - 14} {center[1]} A14 14 0 0 1 {center[0] + 14} {center[1]}Z" '
                 f'fill="{LIGHT}" {OUTLINE}/>')
    spokes = rays(center, ((19, 25), (200, 235, 270, 305, 340)))
    horizon = f'<path d="M6 {center[1]}H58" fill="none" {OUTLINE}/>'
    arrow = "M32 61V49M27 54L32 49L37 54" if rising else "M32 49V61M27 56L32 61L37 56"
    pointer = f'<path d="{arrow}" fill="none" {OUTLINE.replace("3.5", DETAIL_OUTLINE_WIDTH)}/>'
    mood = "happy" if rising else "sleepy"
    return spokes + half_disc + eyes((center[0], center[1] - 7), mood) + horizon + pointer


def bolt():
    return f'<path d="M37.7 30.5L26.9 46.7H33.65L28.9 62.9L43.8 42H36.35L41.75 30.5Z" fill="{LIGHT}" {OUTLINE.replace("3.5", DETAIL_OUTLINE_WIDTH)}/>'


ICONS = {
    "clear": lambda: sun(),
    "clear_night": lambda: moon("translate(-4 0)") + star((52, 14), 6),
    "partly": lambda: small_sun() + cloud((WHITE, "happy"), (3, 8)),
    "partly_night": lambda: moon("translate(1 -3) scale(0.55)") + cloud((WHITE, "sleepy"), (3, 8)),
    "cloudy": lambda: cloud((WHITE, "happy"), (-1, 2)),
    "fog": lambda: cloud((WHITE, "sleepy"), FOG_CLOUD) + mist(),
    "drizzle": lambda: cloud((LIGHT, "happy"), RAISED_CLOUD) + drop((25, 53), 4.5) + drop((41, 53), 4.5),
    "rain": lambda: cloud((MID, "sad"), RAISED_CLOUD) + drop((21, 52), 5.5) + drop((33, 57), 5.5)
    + drop((45, 52), 5.5),
    "sleet": lambda: cloud((LIGHT, "sad"), RAISED_CLOUD) + drop((21, 52), 5) + snowflake((33, 56))
    + drop((45, 52), 5),
    "snow": lambda: cloud((WHITE, "happy"), RAISED_CLOUD) + snowflake((21, 52)) + snowflake((33, 57))
    + snowflake((45, 52)),
    "sunrise": lambda: horizon_sun(True),
    "sunset": lambda: horizon_sun(False),
    "thunder": lambda: bolt() + cloud((DARK, "angry"), THUNDER_CLOUD) + drop((19, 50), 4.5) + drop((48, 50), 4.5),
}


def svg_document(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" '
            f'viewBox="0 0 {CANVAS} {CANVAS}">\n{body}\n</svg>\n')


def main():
    for name, draw in ICONS.items():
        (ICON_DIR / f"{name}.svg").write_bytes(svg_document(draw()).encode("utf-8"))
        print("wrote", name)


if __name__ == "__main__":
    main()
