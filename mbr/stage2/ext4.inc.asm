%ifndef EXT4_ASM_INC
%define EXT4_ASM_INC

struc _ext4_superblock
    .inodes_count: resb 4 ; Total inode count
    .blocks_count_lo: resb 4 ; Total block count
    .r_blocks_count_lo: resb 4 ; Superuser only blocks
    .free_blocks_count_lo: resb 4 ; Free block count
    .free_inodes_count_lo: resb 4 ; Free inode count
    .first_data_block: resb 4 ; First data block. Must be at least 1 for 1K block size, typically 0 otherwise
    .log_block_size: resb 4 ; Block size = 2 ^ (10 + s_log_block_size)
    .log_cluster_size: resb 4 ; Cluster size = 2 ^ s_log_cluster_size if bigalloc enabled, otherwise must equal s_log_block_size
    .blocks_per_group: resb 4 ; Blocks per group
    .cluster_per_group: resb 4 ; Clusters per group if bigalloc is enabled. Otherwise must equal s_blocks_per_group
    .inodes_per_group: resb 4 ; Inodes per group
    .mtime: resb 4 ; Mount time, epoch time
    .wtime: resb 4 ; Write time, epoch time
    .mnt_count: resb 2 ; Mount count since last fsck
    .max_mnt_count: resb 2 ; Mounts until fsck required
    .magic: resb 2 ; Magic signature
    .state: resb 2 ; File system state
    .errors: resb 2 ; Behavior when detecting errors
    .minor_rev_level: resb 2 ; Minor rev
    .lastcheck: resb 4 ; Last fsck, epoch time
    .checkinterval: resb 4 ; Max time between fsck, in seconds
    .creator_os: resb 4 ; Creator OS. Will ignore
    .rev_level: resb 4 ; Revision level
    .def_resuid: resb 2 ; Default UID for reserved blocks
    .def_resgid: resb 2 ; Default GID for reserved blocks
    ; DYNAMIC_REV superblocks only
    .first_ino: resb 4 ; First non-reserved inode
    .inode_size: resb 2 ; Size of inode structure in byte
    .block_group_nr: resb 2 ; Block group # of this superblock
    .feature_compat: resb 4 ; Allowed to mount this FS even if we don't understand these
    .feature_incompat: resb 4 ; Not allowed to mount this if we don't understand these
    .feature_ro_compat: resb 4 ; Also allowed to mount without understanding these (we aren't doing writes)
    .uuid: resb 16 ; UUID for FS
    .volume_name: resb 16 ; Volume label
    .last_mounted: resb 64 ; Last mounted directory
    .algorithm_usage_bitmap: resb 4 ; For compression
    ; Performance hints - not going to bother
    .prealloc_blocks: resb 1
    .prealloc_dir_blocks: resb 1
    .reserved_gdt_blocks: resb 2
    ; Journaling support - probably don't have to care
    .journal_uuid: resb 16
    .journal_inum: resb 4
    .journal_dev: resb 4
    .last_orphan: resb 4
    .hash_seed: resb 16
    .def_hash_version: resb 1
    .jnl_backup_type: resb 1
    .desc_size: resb 2
    .default_mount_opts: resb 4
    .first_meta_bg: resb 4
    .mkfs_time: resb 4
    .jnl_blocks: resb 68
    ; 64-bit feature
    .blocks_count_hi: resb 4 ; Upper 32-bits of the block count
    .r_blocks_count_hi: resb 4 ; Upper 32-bits of the reserved block count
    .free_blocks_count_hi: resb 4 ; Upper 32-bits of the free block count
    .min_extra_isize: resb 2 ; All inodes have at least # bytes
    .want_extra_isize: resb 2 ; New inodes should reserve # bytes
    .flags: resb 4 ; Misc. flags
    .raid_stride: resb 2
    .mmp_interval: resb 2
    .mmp_block: resb 8
    .raid_stripe_width: resb 4
    .log_groups_per_flex: resb 1
    .checksum_type: resb 1
    .reserved_pad: resb 2
    .kbytes_written: resb 8
    .snapshot_inum: resb 4
    .snapshot_id: resb 4
    .snapshot_r_blocks_count: resb 8
    .snapshot_list: resb 4
    .error_count: resb 4
    .first_error_time: resb 4
    .first_error_ino: resb 4
    .first_error_block: resb 8
    .first_error_func: resb 32
    .first_error_line: resb 4
    .last_error_time: resb 4
    .last_error_ino: resb 4
    .last_error_line: resb 4
    .last_error_block: resb 8
    .last_error_func: resb 32
    .mount_opts: resb 64
    .usr_quota_inum: resb 4
    .grp_quota_inum: resb 4
    .overhead_blocks: resb 4
    .backup_bgs: resb 8
    .encrypt_algos: resb 4
    .encrypt_pw_salt: resb 16
    .lpf_ino: resb 4
    .prj_quota_inum: resb 4
    .checksum_seed: resb 4
    .reserved: resb 98 * 4
    .checksum: resb 4 ; Superblock checksum
endstruc
EXT4_SUPERBLOCK_MAGIC equ 0xEF53

EXT4_SUPERBLOCK_STATE_CLEAN equ 0x0001
EXT4_SUPERBLOCK_STATE_ERROR equ 0x0002
EXT4_SUPERBLOCK_STATE_ORPHANS equ 0x0004

EXT4_SUPERBLOCK_ERRORS_CONTINUE equ 0x0001
EXT4_SUPERBLOCK_ERRORS_REMOUNT_RO equ 0x0002
EXT4_SUPERBLOCK_ERRORS_PANIC equ 0x0003

EXT4_SUPERBLOCK_REV_LEVEL_ORIG equ 0
EXT4_SUPERBLOCK_REV_LEVEL_DYNAMIC_REV equ 1

EXT4_SUPERBLOCK_FEATURE_COMPAT_DIR_PREALLOC equ 0x0001
EXT4_SUPERBLOCK_FEATURE_COMPAT_IMAGIC_INODES equ 0x0002
EXT4_SUPERBLOCK_FEATURE_COMPAT_HAS_JOURNAL equ 0x0004
EXT4_SUPERBLOCK_FEATURE_COMPAT_EXT_ATTR equ 0x0008
EXT4_SUPERBLOCK_FEATURE_COMPAT_RESIZE_INODE equ 0x0010
EXT4_SUPERBLOCK_FEATURE_COMPAT_DIR_INDEX equ 0x0020
EXT4_SUPERBLOCK_FEATURE_COMPAT_LAZY_BG equ 0x0040
EXT4_SUPERBLOCK_FEATURE_COMPAT_EXCLUDE_INODE equ 0x0080
EXT4_SUPERBLOCK_FEATURE_COMPAT_EXCLUDE_BITMAP equ 0x0100
EXT4_SUPERBLOCK_FEATURE_COMPAT_SPARSE_SUPER2 equ 0x0200
EXT4_SUPERBLOCK_FEATURE_COMPAT_FAST_COMMIT equ 0x0400
EXT4_SUPERBLOCK_FEATURE_COMPAT_ORPHAN_PRESENT equ 0x1000

EXT4_SUPERBLOCK_FEATURE_INCOMPAT_COMPRESSION equ 0x00001
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_FILETYPE equ 0x00002
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_RECOVER equ 0x00004
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_JOURNAL_DEV equ 0x00008
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_META_BG equ 0x00010
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_EXTENTS equ 0x00040
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_64BIT equ 0x00080
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_MMP equ 0x00100
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_FLEX_BG equ 0x00200
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_EA_INODE equ 0x00400
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_DIRDATA equ 0x01000
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_CSUM_SEED equ 0x02000
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_LARGEDIR equ 0x04000
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_INLINE_DATA equ 0x08000
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_ENCRYPT equ 0x10000

; For now, only support 64-bit
; FILETYPE | EXTENTS | 64BIT | FLEX_BG | CSUM_SEED
EXT4_SUPERBLOCK_FEATURE_INCOMPAT_SUPPORTED equ 0x022C2

EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_SPARSE_SUPER equ 0x0001
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_LARGE_FILE equ 0x0002
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_BTREE_DIR equ 0x0004
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_HUGE_FILE equ 0x0008
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_GDT_CSUM equ 0x0010
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_DIR_NLINK equ 0x0020
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_EXTRA_ISIZE equ 0x0040
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_HAS_SNAPSHOT equ 0x0080
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_QUOTA equ 0x0100
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_BIGALLOC equ 0x0200
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_METADATA_CSUM equ 0x0400
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_REPLICA equ 0x0800
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_READONLY equ 0x1000
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_PROJECT equ 0x2000
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_VERITY equ 0x8000
EXT4_SUPERBLOCK_FEATURE_RO_COMPAT_ORPHAN_PRESENT equ 0x10000

struc _ext4_group_desc
    .block_bitmap_lo: resb 4 ; block bitmap address
    .inode_bitmap_lo: resb 4 ; inode bitmap address
    .inode_table_lo: resb 4 ; inode table address
    .free_blocks_count_lo: resb 2 ; Free block count
    .free_inodes_count_lo: resb 2 ; Free inode count
    .used_dirs_count_lo: resb 2 ; Directory count
    .flags: resb 2 ; Block group flags
    .exclude_bitmap_lo: resb 4 ; Snapshot exclusion bitmap
    .block_bitmap_csum_lo: resb 2 ; Block bitmap checksum
    .inode_inode_bitmap_csum_lo: resb 2 ; Inode bitmap checksum
    .itable_unused_lo: resb 2 ; Unused inode count
    .checksum: resb 2
    .block_bitmap_hi: resb 4
    .inode_bitmap_hi: resb 4
    .inode_table_hi: resb 4
    .free_blocks_count_hi: resb 2
    .free_inodes_count_hi: resb 2
    .used_dirs_count_hi: resb 2
    .itable_unused_hi: resb 2
    .exclude_bitmap_hi: resb 4
    .block_bitmap_csum_hi: resb 2
    .inode_bitmap_csum_hi: resb 2
    .bg_reserved: resb 4
endstruc

EXT4_BLOCK_GROUP_FLAGS_INODE_UNINIT equ 0x01
EXT4_BLOCK_GROUP_FLAGS_BLOCK_UNINIT equ 0x02
EXT4_BLOCK_GROUP_FLAGS_INODE_ZEROED equ 0x04

struc _ext4_inode
    .mode: resb 2 ; File mode
    .uid: resb 2 ; Owner ID
    .size_lo: resb 4 ; Size in bytes
    .atime: resb 4 ; Last access time
    .ctime: resb 4 ; Last inode change time
    .mtime: resb 4 ; Last data modification time
    .dtime: resb 4 ; Delete time
    .gid: resb 2 ; GID
    .links_count: resb 2 ; Hard link count
    .blocks_lo: resb 4 ; Block count
    .flags: resb 4 ; Inode flags
    .osd1: resb 4 ; Ignored
    .block: resb 60 ; Block map
    .generation: resb 4 ; File version
    .file_acl_lo: resb 4 ; ACLs
    .size_hi: resb 4 ; Upper file/dir size
    .obso_faddr: resb 4
    .osd2: resb 12
    .extra_isize: resb 2 ; Size of this inode - 128
    .checksum_hi: resb 2
    .ctime_extra: resb 4
    .mtime_extra: resb 4
    .atime_extra: resb 4
    .crtime: resb 4 ; File creation time
    .crtime_extra: resb 4
    .version_hi: resb 4
    .projid: resb 4
endstruc

EXT4_S_IXOTH equ 0x0001
EXT4_S_IWOTH equ 0x0002
EXT4_S_IROTH equ 0x0004
EXT4_S_IXGRP equ 0x0008
EXT4_S_IWGRP equ 0x0010
EXT4_S_IRGRP equ 0x0020
EXT4_S_IXUSR equ 0x0040
EXT4_S_IWUSR equ 0x0080
EXT4_S_IRUSR equ 0x0100
EXT4_S_ISVTX equ 0x0200
EXT4_S_ISGID equ 0x0400
EXT4_S_ISUID equ 0x0800
EXT4_S_IFIFO equ 0x1000
EXT4_S_IFCHR equ 0x2000
EXT4_S_IFDIR equ 0x4000
EXT4_S_IFBLK equ 0x6000
EXT4_S_IFREG equ 0x8000
EXT4_S_IFLNK equ 0xA000
EXT4_S_IFSOCK equ 0xC000

EXT4_INODE_FLAG_SECRM equ 0x00000001
EXT4_INODE_FLAG_UNRM equ 0x00000002
EXT4_INODE_FLAG_COMPR equ 0x00000004
EXT4_INODE_FLAG_SYNC equ 0x00000008
EXT4_INODE_FLAG_IMMUTABLE equ 0x00000010
EXT4_INODE_FLAG_APPEND equ 0x00000020
EXT4_INODE_FLAG_NODUMP equ 0x00000040
EXT4_INODE_FLAG_NOATIME equ 0x00000080
EXT4_INODE_FLAG_DIRTY equ 0x00000100
EXT4_INODE_FLAG_COMPRBLK equ 0x00000200
EXT4_INODE_FLAG_NOCOMPR equ 0x00000400
EXT4_INODE_FLAG_ENCRYPT equ 0x00000800
EXT4_INODE_FLAG_INDEX equ 0x00001000
EXT4_INODE_FLAG_IMAGIC equ 0x00002000
EXT4_INODE_FLAG_JOURNAL_DATA equ 0x00004000
EXT4_INODE_FLAG_NOTAIL equ 0x00008000
EXT4_INODE_FLAG_DIRSYNC equ 0x00010000
EXT4_INODE_FLAG_TOPDIR equ 0x00020000
EXT4_INODE_FLAG_HUGE_FILE equ 0x00040000
EXT4_INODE_FLAG_EXTENTS equ 0x00080000
EXT4_INODE_FLAG_EA_INODE equ 0x00200000
EXT4_INODE_FLAG_EOFBLOCKS equ 0x00400000
EXT4_INODE_FLAG_SNAPFILE equ 0x01000000
EXT4_INODE_FLAG_SNAPFILE_DELETED equ 0x04000000
EXT4_INODE_FLAG_SNAPFILE_SHRUNK equ 0x08000000
EXT4_INODE_FLAG_INLINE_DATA equ 0x10000000
EXT4_INODE_FLAG_PROJINHERIT equ 0x20000000
EXT4_INODE_FLAG_RESERVED equ 0x80000000

struc ext4_inode_iblock_symlink
endstruc

struc _ext4_inode_iblock_map
    .direct: resb 12 * 4 ; Direct map to file blocks 0 to 11
    .indirect: resb 4 ; Block number containing a list of pointers to blocks
    .double_indirect: resb 4 ; block number containing a list of pointers to (a list of pointers to blocks)
    .triple_indirect: resb 4 ; block number containing a list of pointers to (a list of pointers to (a list of pointers to blocks))
endstruc

struc _ext4_extent_header
    .magic: resb 2 ; Magic number
    .entries: resb 2 ; Number of valid entries following the header
    .max: resb 2 ; Maximum entires that could follow the header
    .depth: resb 2 ; Layers of indirection for nodes following
    .generation: resb 4 ; unused?
endstruc
EXT4_EXTENT_HEADER_MAGIC equ 0xF30A
EXT4_EXTENT_HEADER_DEPTH_MAX equ 5

struc _ext4_extent_idx
    .block: resb 4 ; Start block for this node
    .leaf_lo: resb 4 ; Block number of the extent node that is the next level lower in the tree. Can either be another idx node or a leaf node
    .leaf_hi: resb 2 ; upper 16-bits of previous
    .unused: resb 2
endstruc

struc _ext4_extent
    .block: resb 4 ; first lbock number that this extent covers
    .len: resb 2 ; Number of blocks covered
    .start_hi: resb 2 ; Upper 16-bits of blocks pointed to
    .start_lo: resb 2 ; Lower 32-bits of block number
endstruc

struc _ext4_dir_entry
    .inode: resb 4 ; inode that this entry points to
    .rec_len: resb 2 ; Length of this directory entry
    .name_len: resb 1 ; Length of the file name
    .file_type: resb 1
    .name: resb 255
endstruc
EXT4_NAME_LEN equ 255

EXT4_MAX_BLOCK_SIZE equ 4096

%ifndef EXT4_ASM_INC_NO_EXTERN
extern ext4_kernel_inode
extern ext4_block_size

extern ext4_init ; void ext4_init()

extern ext4_get_inode_block ; int ext4_get_inode_block(struct ext4_inode *inode, uint32_t block, uint8_t *buf)
extern ext4_get_file_size ; uint64_t ext4_get_file_size(struct ext4_inode *inode)
extern ext4_byte_to_block ; uint64_t ext4_byte_to_block(uint64_t byte_offset)
extern ext4_byte_to_block_offset ; uint32_t ext4_byte_to_block_offset(uint64_t byte_offset)
%endif
%endif
