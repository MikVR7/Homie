import os
import json

def discover_folders(base_path):
    folder_map = {}
    for root, dirs, files in os.walk(base_path):
        folder_map[root] = {
            "dirs": dirs,
            "files": {file: extract_file_metadata(os.path.join(root, file)) for file in files}
        }
    return folder_map

def extract_file_metadata(file_path):
    """Extract metadata for a given file"""
    try:
        stats = os.stat(file_path)
        return {
            "size": stats.st_size,
            "modified_time": stats.st_mtime,
            "created_time": stats.st_ctime,
            "type": "directory" if os.path.isdir(file_path) else "file"
        }
    except FileNotFoundError:
        return None

def save_folder_map(folder_map, file_path='config/folder_map.json'):
    with open(file_path, 'w') as f:
        json.dump(folder_map, f, indent=4)

if __name__ == "__main__":
    project_path = os.path.dirname(os.path.abspath(__file__))
    folders = discover_folders(project_path)
    save_folder_map(folders)
    print(f"Folder map saved to config/folder_map.json")

