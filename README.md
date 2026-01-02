<samp>

# ss

a command-line tool for creating and managing directory snapshots. save the state of your project directory and restore it later with ease.

## Features

- **Snapshot directories** - Create encrypted snapshots of any directory
- **Custom IDs** - Assign custom identifiers to your snapshots
- **List snapshots** - View all saved snapshots
- **Restore snapshots** - Load snapshots back to your filesystem
- **Preview contents** - View snapshot structure before restoring
- **Progress tracking** - Visual progress bars for long operations
- **Encrypted storage** - AES-256-CBC encryption for security

## Installation

### Prerequisites

- Crystal 1.18.2 or higher

### Build from source

```bash
# Clone the repository
git clone https://github.com/myferr/ss.git
cd ss/

# Build
shards build
```

### Install to system path

```bash
# After building, copy the binary to your PATH
cp bin/ss /usr/local/bin/
# or
mv bin/ss /usr/local/bin/
```

## Usage

### Basic Commands

#### Snap a directory

```
# Snapshot current directory
ss snap

# Snapshot a specific directory
ss snap /path/to/project

# Snapshot with a custom ID
ss snap --id my-project
```

#### List snapshots

```
ss list
```

#### Load/restore a snapshot

```
# Load snapshot to current directory (with confirmation)
ss load <snapshot-file>

# Load snapshot to a different directory
ss load <snapshot-file> --dir /path/to/restore

# Preview snapshot contents without loading
ss load <snapshot-file> --preview
```

#### Remove a snapshot

```
ss remove <snapshot-file>
```

### Command Reference

| Command                | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `ss snap [dir]`        | Create a snapshot of a directory (or cwd if not specified) |
| `ss list`              | List all saved snapshots                                   |
| `ss load <snapshot>`   | Load and restore a snapshot                                |
| `ss remove <snapshot>` | Delete a snapshot                                          |

### Options

| Option        | Short | Description                         |
| ------------- | ----- | ----------------------------------- |
| `--id VALUE`  | -     | Provide an ID for your snapshot     |
| `--dir VALUE` | -D    | Load snapshot to specific directory |
| `--preview`   | -P    | Preview snapshot contents           |
| `--help`      | -h    | Show help message                   |
| `--version`   | -v    | Show version information            |

## How it Works

1. **Storage**: Snapshots are stored in `~/.ss/` directory with `.snap` extension
2. **Encryption**: All snapshots are encrypted using AES-256-CBC encryption
3. **Structure**: Snapshots preserve directory structure and file contents using Base64 encoding
4. **Filenames**: Snapshot files are named as `<timestamp>-<id>.snap`

## Examples

### Snapshot a project with custom ID

```
$ ss snap --id my-awesome-project
Snapshotting.. | ██████████ |

Saved! View here: ~/.ss/1735814400-my-awesome-project.snap
```

### List all snapshots

```
$ ss list
you have 2 snapshots.

- 1735814400-my-awesome-project.snap
- 1735814500-backup.snap
```

### Preview a snapshot

```
$ ss load 1735814400-my-awesome-project.snap --preview
src
  ss.cr
  loader.cr
  snap_file.cr
  snapshot.cr
shard.yml
```

### Load a snapshot to a different directory

```
$ ss load 1735814400-my-awesome-project.snap --dir /tmp/restore
You sure you want to load snapshot (y/N)?: y
Loading snapshot... | ██████████ |

Loaded!
```

## License

MIT

</samp>
