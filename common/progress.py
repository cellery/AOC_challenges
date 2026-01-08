import sys
import time

def update_progress(current: int, total: int, prefix: str = '', bar_length: int = 40) -> None:
    """Print a simple progress bar to the terminal.

    Args:
        current: current 1-based index of the item being processed.
        total: total number of items.
        prefix: optional text prefix shown before the bar.
        bar_length: width of the progress bar in characters.

    Example:
        for i, line in enumerate(lines, start=1):
            update_progress(i, len(lines), prefix='Processing')
    """
    if total <= 0:
        return
    if current < 0:
        current = 0
    if current > total:
        current = total

    fraction = current / total
    filled = int(round(bar_length * fraction))
    bar = '█' * filled + '-' * (bar_length - filled)
    percent = int(round(100 * fraction))
    sys.stdout.write(f"\r{prefix} |{bar}| {percent:3d}% ({current}/{total})")
    sys.stdout.flush()
    if current == total:
        sys.stdout.write('\n')


def process_file_with_progress(filepath: str, line_processor=None, sleep_per_line: float = 0.0):
    """Read a text file line-by-line and show progress.

    Args:
        filepath: path to the text file.
        line_processor: optional function called with each line (and index starting at 1).
        sleep_per_line: optional small delay to simulate work (seconds).
    """
    # First pass: count lines
    with open(filepath, 'r', encoding='utf-8') as f:
        total = sum(1 for _ in f)

    if total == 0:
        print('Empty file: no lines to process')
        return

    # Second pass: process lines with progress
    with open(filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, start=1):
            if line_processor:
                line_processor(line.rstrip('\n'), i)
            if sleep_per_line:
                time.sleep(sleep_per_line)
            update_progress(i, total, prefix='Processing')
