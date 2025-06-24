%define EXT4_ASM_INC_NO_EXTERN
%include "stage2/ext4.asm.inc"
%include "stage2/disk.asm.inc"
%include "stage2/bootloader.asm.inc"
%include "stage2/util.asm.inc"
%include "stage2/print.asm.inc"
%include "stage2/interrupt.asm.inc"
%include "stage2/timer.asm.inc"

bits 32

extern __ashldi3
extern __ashrdi3
extern __muldi3
extern __udivdi3
extern __udivmoddi4

section .data

target_file_name: db "kernel.elf", 0
target_file_name_len: db 10

section .bss

fname_buf: resb EXT4_NAME_LEN + 1
sector_block_conv: resb 1

alignb 4
block_size: resb 4

alignb 4
sector_buffer: resb DISK_SECTOR_SIZE

alignb 4
superblock: resb _ext4_superblock_size

alignb 4
inode_buffer: resb _ext4_inode_size

alignb 4
block_group_buffer: resb _ext4_group_desc_size

alignb 4
block_buffer: resb EXT4_MAX_BLOCK_SIZE

alignb 4
inode_map_buffer: resb EXT4_MAX_BLOCK_SIZE * 5

section .text

global ext4_init
ext4_init: ; void ext4_init()
    push ebp
    mov ebp, esp
    push esi
    
    ; Calculate block to lba conversion factor
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10 - DISK_SECTOR_SIZE_LOG
    mov byte [sector_block_conv], cl

    ; Read the superblock
    ; Before the superblock is initialized, block size should be 1024 so we shouldn't overrun the buffer
    push superblock
    push 0
    push 1
    call ext4_read_block
    add esp, 12

    ; Calculate block to lba conversion factor
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10 - DISK_SECTOR_SIZE_LOG
    mov byte [sector_block_conv], cl

    mov eax, 1
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10
    shl eax, cl
    mov dword [block_size], eax

    call ext4_is_compat
    cmp eax, 0
    jne .exit

    ; The kernel inode should be in inode_buffer if this succeeds
    call ext4_find_kernel
    cmp eax, 0
    jmp .file_found
    mov eax, 1
    jmp .exit
.file_found:
    mov esi, inode_buffer

    xor eax, eax
.exit:
    pop esi
    pop ebp
    ret

ext4_find_kernel: ; int ext4_find_kernel()
    push ebp
    mov ebp, esp
    push edi

    ; Parse block group structure
    push inode_buffer
    push 0
    push 2
    call ext4_get_inode
    add esp, 12

    ; This function should put the kernel inode in edx:eax, or zero if not found
    push target_file_name
    push inode_buffer
    call ext4_find_file
    add esp, 8

    mov ecx, eax
    or ecx, edx
    cmp ecx, 0
    jne .file_found
    mov eax, 1
    jmp .exit
.file_found:

    push inode_buffer
    push edx
    push eax
    call ext4_get_inode
    add esp, 12

    xor eax, eax
.exit:
    pop edi
    pop ebp
    ret

struc _ext4_get_inode_block_extents_local
    .index: resb 2
    .count: resb 2
    .header: resb 4
    .node: resb 4
    .depth: resb 4
endstruc
ext4_get_inode_block_extents: ; int ext4_get_inode_block_extends(struct ext4_inode *inode, uint32_t block, uint8_t *buf)
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov esi, dword [ebp + 8]

    ; Check file size against file block limit
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10
    push ecx
    push dword [esi + _ext4_inode.size_hi]
    push dword [esi + _ext4_inode.size_lo]
    call __ashrdi3
    add esp, 12
    cmp edx, 0
    jg .block_n_valid
    cmp dword [ebp + 12], eax
    jge .failure
.block_n_valid:
    ; Check inode extent magic
    add esi, _ext4_inode.block
    cmp word [esi + _ext4_extent_header.magic], EXT4_EXTENT_HEADER_MAGIC
    jnz .failure
    cmp word [esi + _ext4_extent_header.depth], EXT4_EXTENT_HEADER_DEPTH_MAX
    jg .failure

    ; Setup initial tree structure
    ; Copy first level extent structure
    mov eax, _ext4_extent_size
    mul word [esi + _ext4_extent_header.entries]
    add eax, _ext4_extent_header_size
    mov edi, inode_map_buffer
    push eax
    push esi
    push edi
    call memcpy
    add esp, 12

    sub esp, _ext4_get_inode_block_extents_local_size
    mov word [esp + _ext4_get_inode_block_extents_local.index], 0
    mov ax, word [edi + _ext4_extent_header.entries]
    mov word [esp + _ext4_get_inode_block_extents_local.count], ax
    mov dword [esp + _ext4_get_inode_block_extents_local.depth], 1
    mov eax, edi
    mov dword [esp + _ext4_get_inode_block_extents_local.header], eax
    add eax, _ext4_extent_header_size
    mov dword [esp + _ext4_get_inode_block_extents_local.node], eax

    ; Walk the tree
.walk_tree:
    ; Compare our progress through this branch
    mov ax, word [esp + _ext4_get_inode_block_extents_local.index]
    cmp ax, word [esp + _ext4_get_inode_block_extents_local.count]
    jge .walk_tree.leaf_done ; We're done with this branch, go back up one level
    ; Check whether the next node will be an index node or data node
    mov edi, dword [esp + _ext4_get_inode_block_extents_local.header]
    cmp dword [edi + _ext4_extent_header.depth], 0
    jz .walk_tree.data_node
.walk_tree.index_node:
    mov edi, dword [esp + _ext4_get_inode_block_extents_local.node]
    mov eax, dword [edi + _ext4_extent_idx.block]
    cmp dword [ebp + 12], eax
    jg .walk_tree.index_node.skip
    ; Descend
    ; Setup new structure
    mov esi, esp ; Temporarily hold ptr to current state
    sub esp, _ext4_get_inode_block_extents_local_size
    mov word [esp + _ext4_get_inode_block_extents_local.index], 0
    mov eax, dword [esi + _ext4_get_inode_block_extents_local.header]
    add eax, dword [block_size]
    mov dword [esp + _ext4_get_inode_block_extents_local.header], eax
    add eax, _ext4_extent_header_size
    mov dword [esp + _ext4_get_inode_block_extents_local.node], eax
    mov eax, dword [esi + _ext4_get_inode_block_extents_local.depth]
    add eax, 1
    mov dword [esp + _ext4_get_inode_block_extents_local.depth], eax
    cmp eax, EXT4_EXTENT_HEADER_DEPTH_MAX ; Make sure we don't walk too far?
    jne .walk_tree.index_node.new_node_failed
    ; Read new block
    xor edx, edx
    mov dx, word [edi + _ext4_extent_idx.leaf_hi]
    mov eax, dword [edi + _ext4_extent_idx.leaf_lo]
    push dword [esp + _ext4_get_inode_block_extents_local.header]
    push edx
    push eax
    call ext4_read_block
    add esp, 12
    mov edi, [esp + _ext4_get_inode_block_extents_local.header]
    mov eax, dword [edi + _ext4_extent_header.entries]
    mov dword [esp + _ext4_get_inode_block_extents_local.count], eax
    ; Sanity check our new nodes
    cmp dword [edi + _ext4_extent_header.magic], EXT4_EXTENT_HEADER_MAGIC
    jne .walk_tree.index_node.new_node_failed
    ; Start again
    jmp .walk_tree
.walk_tree.index_node.new_node_failed:
    add esp, _ext4_get_inode_block_extents_local_size
.walk_tree.index_node.skip:
    add dword [esp + _ext4_get_inode_block_extents_local.index], 1
    add dword [esp + _ext4_get_inode_block_extents_local.node], _ext4_extent_idx_size
    jmp .walk_tree
.walk_tree.data_node:
    mov edi, dword [esp + _ext4_get_inode_block_extents_local.node]
    mov eax, dword [edi + _ext4_extent.block]
    cmp dword [ebp + 12], eax
    jl .walk_tree.index_node.skip ; Our block is less than the start
    mov ecx, dword [edi + _ext4_extent.len]
    cmp ecx, 32768
    jl .walk_tree.data_node.extent_initialized
    sub ecx, 32768
.walk_tree.data_node.extent_initialized:
    add eax, ecx
    cmp dword [ebp + 12], eax
    jge .walk_tree.data_node.skip ; Our block is greater than the end
    ; We found the block!
    mov eax, dword [edi + _ext4_extent.start_lo]
    xor edx, edx
    mov dx, word [edi + _ext4_extent.start_hi]
    push dword [ebp + 16]
    push edx
    push eax
    call ext4_read_block
    add esp, 12
    jmp .unwind_tree
.walk_tree.data_node.skip:
    add dword [esp + _ext4_get_inode_block_extents_local.index], 1
    add dword [esp + _ext4_get_inode_block_extents_local.node], _ext4_extent_size
    jmp .walk_tree
.walk_tree.leaf_done:
    ; If we've walked the entire tree, we've failed
    cmp dword [esp + _ext4_get_inode_block_extents_local.depth], 1
    je .fail_to_find
    ; Otherwise, pop this entry from the stack
    add esp, _ext4_get_inode_block_extents_local_size
    add word [esp + _ext4_get_inode_block_extents_local.index], 1
    add dword [esp + _ext4_get_inode_block_extents_local.node], _ext4_extent_idx_size
    jmp .walk_tree 
.unwind_tree:
    mov eax, _ext4_get_inode_block_extents_local_size
    mov ecx, dword [esp + _ext4_get_inode_block_extents_local.depth]
    mul ecx
    add esp, eax
    xor eax, eax
    jmp .exit
.fail_to_find:
    add esp, _ext4_get_inode_block_extents_local_size
.failure:
    mov eax, 1
.exit:
    pop edi
    pop esi
    pop ebp
    ret

ext4_get_inode_block_pointer: ; int ext4_get_inode_block_pointer(struct ext4_inode *inode, uint32_t block, uint8_t *buf)
    push ebp
    mov ebp, esp

    mov eax, 1

    pop ebp
    ret

ext4_get_inode_block: ; int ext4_get_inode_block(struct ext4_inode *inode, uint32_t block, uint8_t *buf)
    push ebp
    mov ebp, esp
    push esi

    mov esi, dword [ebp + 8]
    push dword [ebp + 16]
    push dword [ebp + 12]
    push dword [ebp + 8]
    test dword [esi + _ext4_inode.flags], EXT4_INODE_FLAG_EXTENTS
    jnz .extents
    call ext4_get_inode_block_pointer
    jmp .exit
.extents:
    call ext4_get_inode_block_extents
.exit:
    add esp, 12
    pop esi
    pop ebp
    ret

struc _ext4_find_file_flat_local
    .block_count: resb 4
    .block: resb 4
    .block_offset: resb 4
endstruc
ext4_find_file_flat: ; uint64_t ext4_find_file_flat(struct ext4_inode *dir, uint8_t *name)
    push ebp
    mov ebp, esp
    push edi
    push esi

    sub esp, _ext4_find_file_flat_local_size
    mov esi, dword [ebp + 8]
    mov edi, block_buffer
    mov dword [esp + _ext4_find_file_flat_local.block], 0
    mov dword [esp + _ext4_find_file_flat_local.block_offset], 0

    ; Calculate block count
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10
    push ecx
    push dword [esi + _ext4_inode.size_hi]
    push dword [esi + _ext4_inode.size_lo]
    call __ashrdi3
    add esp, 12
    mov dword [esp + _ext4_find_file_flat_local.block_count], eax

.search_outer:
    mov edi, block_buffer
    mov eax, dword [esp + _ext4_find_file_flat_local.block]
    push block_buffer
    push eax
    push dword [ebp + 8]
    call ext4_get_inode_block
    add esp, 12
.search_outer.inner:
    cmp dword [edi + _ext4_dir_entry.inode], 0 ; Skip invalid entry
    jz .search_outer.inner.inc
    cmp word [edi + _ext4_dir_entry.rec_len], 0 ; Don't know how to recover if rec_len is 0
    jz .fail_to_find
    ; Parse the current entry
    push edi
    call ext4_print_dir_entry
    add esp, 4

    xor ecx, ecx
    mov cl, byte [target_file_name_len]
    cmp byte [edi + _ext4_dir_entry.name_len], cl
    jne .search_outer.inner.inc
    push ecx
    push target_file_name
    lea eax, byte [edi + _ext4_dir_entry.name]
    push eax
    call memcmp
    add esp, 12
    cmp eax, 0
    jz .inode_found
.search_outer.inner.inc:
    xor ax, ax
    mov ax, word [edi + _ext4_dir_entry.rec_len]
    add edi, eax
    add dword [esp + _ext4_find_file_flat_local.block_offset], eax
    mov eax, dword [block_size]
    cmp dword [esp + _ext4_find_file_flat_local.block_offset], eax ; See if we've hit the end of the block
    jl .search_outer.inner
.search_outer.inc:
    add dword [esp + _ext4_find_file_flat_local.block], 1
    mov dword [esp + _ext4_find_file_flat_local.block_offset], 0
    mov eax, dword [esp + _ext4_find_file_flat_local.block_count]
    cmp dword [esp + _ext4_find_file_flat_local.block], eax
    jl .search_outer
.fail_to_find:
    xor eax, eax
    xor edx, edx
    jmp .exit
.inode_found:
    xor edx, edx
    mov eax, dword [edi + _ext4_dir_entry.inode]
.exit:
    add esp, _ext4_find_file_flat_local_size
    pop esi
    pop edi
    pop ebp
    ret

ext4_find_file_tree: ; uint64_t ext4_find_file_tree(struct ext4_inode *dir, uint8_t *name)
    push ebp
    mov ebp, esp

    xor edx, edx
    xor eax, eax

    pop ebp
    ret

ext4_find_file: ; uint64_t ext4_find_file(struct ext4_inode *dir, uint8_t *name)
    push ebp
    mov ebp, esp
    push esi

    mov esi, dword [ebp + 8]
    test word [esi + _ext4_inode.mode], EXT4_S_IFDIR
    jz .not_found

    push dword [ebp + 12]
    push dword [ebp + 8]
    test dword [esi + _ext4_inode.flags], EXT4_INODE_FLAG_INDEX
    jz .flat
    call ext4_find_file_tree
    jmp .fexit
.flat:
    call ext4_find_file_flat
.fexit:
    add esp, 8
    jmp .exit
.not_found:
    xor eax, eax
    xor edx, edx
.exit:
    pop esi
    pop ebp
    ret

struc _ext4_get_inode_local
    .index: resb 8
    .block_group: resb 8
    .offset: resb 8
    .block: resb 8
    .block_offset: resb 4
endstruc
ext4_get_inode: ; int ext4_get_inode(uint32_t inode_low, uint32_t inode_high, uint8_t *buf)
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    sub esp, _ext4_get_inode_local_size
    mov edi, esp

    ; bg = (inode_num - 1) / s_inodes_per_group
    ; index = (inode_num - 1) % s_inodes_per_group
    mov eax, dword [ebp + 8]
    mov edx, dword [ebp + 12]
    sub eax, 1
    sbb edx, 0
    mov ecx, dword [superblock + _ext4_superblock.inodes_per_group]
    lea esi, dword [edi + _ext4_get_inode_local.index]
    push esi
    push 0
    push ecx
    push edx
    push eax
    call __udivmoddi4
    add esp, 20
    mov dword [edi + _ext4_get_inode_local.block_group], eax
    mov dword [edi + _ext4_get_inode_local.block_group + 4], edx

    ; offset = index * s_inode_size
    ; Get lower 32-bits
    mov eax, dword [edi + _ext4_get_inode_local.index]
    mul word [superblock + _ext4_superblock.inode_size]
    mov ecx, edx
    mov dword [edi + _ext4_get_inode_local.offset], eax
    ; Get upper 32-bits
    mov eax, dword [edi + _ext4_get_inode_local.index + 4]
    mul word [superblock + _ext4_superblock.inode_size]
    add eax, ecx
    mov dword [edi + _ext4_get_inode_local.offset + 4], eax

    ; block = offset / (1 << (10 + s_log_block_size))
    ; block_offset = offset % (1 << (10 + s_log_block_size))
    mov ecx, 10
    add ecx, dword [superblock + _ext4_superblock.log_block_size]
    mov eax, 1
    shl eax, cl
    lea esi, dword [edi + _ext4_get_inode_local.block_offset]
    push esi
    push 0
    push eax
    push dword [edi + _ext4_get_inode_local.offset + 4]
    push dword [edi + _ext4_get_inode_local.offset]
    call __udivmoddi4
    add esp, 20
    mov dword [edi + _ext4_get_inode_local.block], eax
    mov dword [edi + _ext4_get_inode_local.block + 4], edx

    ; Read block group descriptor
    push block_group_buffer
    push dword [edi + _ext4_get_inode_local.block_group + 4]
    push dword [edi + _ext4_get_inode_local.block_group]
    call ext4_get_block_group_descriptor
    add esp, 12

    mov eax, dword [block_group_buffer + _ext4_group_desc.inode_table_lo]
    xor edx, edx
    cmp dword [superblock + _ext4_superblock.desc_size], _ext4_group_desc.inode_table_hi + 2
    jl .no_upper
    add edx, dword [block_group_buffer + _ext4_group_desc.inode_table_hi]
.no_upper:
    add dword [edi + _ext4_get_inode_local.block], eax
    adc dword [edi + _ext4_get_inode_local.block + 4], edx

    push block_buffer
    push dword [edi + _ext4_get_inode_local.block + 4]
    push dword [edi + _ext4_get_inode_local.block]
    call ext4_read_block
    add esp, 12

    mov eax, dword [edi + _ext4_get_inode_local.block_offset]
    add eax, block_buffer
    mov ecx, dword [ebp + 16]
    xor edx, edx
    mov dx, word [superblock + _ext4_superblock.inode_size]
    push edx
    push eax
    push ecx
    call memcpy
    add esp, 12

    add esp, _ext4_get_inode_local_size
    pop ebx
    pop esi
    pop edi
    pop ebp
    ret

struc _ext4_get_block_group_descriptor_local
    .block: resb 8
    .block_offset: resb 8
endstruc
ext4_get_block_group_descriptor: ; int ext4_get_block_group_descriptor(uint64_t block_group, uint8_t *buf)
    push ebp
    mov ebp, esp
    push edi
    push esi

    sub esp, _ext4_get_block_group_descriptor_local_size
    mov edi, esp

    mov eax, 1
    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    add ecx, 10
    shl eax, cl
    xor ecx, ecx
    mov cx, word [superblock + _ext4_superblock.desc_size]
    div ecx
    mov ecx, eax ; ecx = group descriptors per block

    lea eax, dword [edi + _ext4_get_block_group_descriptor_local.block_offset]
    push eax
    push 0
    push ecx
    push dword [ebp + 12]
    push dword [ebp + 8]
    call __udivmoddi4
    add esp, 20

    mov ecx, dword [superblock + _ext4_superblock.first_data_block]
    add ecx, 1
    add eax, ecx
    adc edx, 0
    mov dword [edi + _ext4_get_block_group_descriptor_local.block], eax
    mov dword [edi + _ext4_get_block_group_descriptor_local.block + 4], edx

    push block_buffer
    push dword [edi + _ext4_get_block_group_descriptor_local.block + 4]
    push dword [edi + _ext4_get_block_group_descriptor_local.block]
    call ext4_read_block
    add esp, 12

    mov eax, dword [ebp + 16]
    mov ecx, dword [edi + _ext4_get_block_group_descriptor_local.block_offset]
    lea esi, dword [eax]
    lea edi, dword [block_buffer + ecx]
    xor ecx, ecx
    mov cx, word [superblock + _ext4_superblock.desc_size]
    push ecx
    push edi
    push esi
    call memcpy
    add esp, 12

    add esp, _ext4_get_block_group_descriptor_local_size
    pop esi
    pop edi
    pop ebp
    ret

ext4_is_compat: ; int ext4_is_compat()
    push ebp
    mov ebp, esp

    mov ecx, dword [superblock + _ext4_superblock.log_block_size]
    mov eax, 1 << 10
    shl eax, cl
    cmp eax, EXT4_MAX_BLOCK_SIZE
    jle .block_size_ok

    push color_err
    push .block_size_str
    call print_str
    add esp, 8
    mov eax, 1
    jmp .exit    

.block_size_ok:
    ; Check incompatible flags
    mov eax, dword [superblock + _ext4_superblock.feature_incompat]
    and eax, ~EXT4_SUPERBLOCK_FEATURE_INCOMPAT_SUPPORTED
    jz .compatible

    ; Print out incompatible flags
    push eax
    push number_string
    call itoa
    add esp, 8
    push color_err
    push .incompat_str
    call print_str
    add esp, 4
    push number_string
    call print_str
    add esp, 8
    call print_newline

    mov eax, 1
    jmp .exit
.compatible:
    ; If this isn't a 64-bit FS, make sure the group descriptor size is accurate
    test dword [superblock + _ext4_superblock.feature_incompat], EXT4_SUPERBLOCK_FEATURE_INCOMPAT_64BIT
    jnz .64_bit
    mov word [superblock + _ext4_superblock.desc_size], 32
.64_bit:

    xor eax, eax
.exit:
    pop ebp
    ret
.block_size_str: db `Block size too large.\n`, 0
.incompat_str: db `Incompatible feature flags set: `, 0

ext4_block_to_lba: ; uint64_t ext4_block_to_lba(uint32_t block_low, uint32_t block_high)
    push ebp
    mov ebp, esp
    push ebx

;    ; Get stuff that should carry over into edx
;    xor ecx, ecx
;    mov cl, 32
;    sub cl, byte [sector_block_conv]
;    mov ebx, dword [ebp + 8]
;    shr ebx, cl
;
;    mov cl, byte [sector_block_conv]
;    mov eax, dword [ebp + 8]
;    shl eax, cl
;    mov edx, dword [ebp + 12]
;    shl edx, cl
;    or edx, ebx

    xor ecx, ecx
    mov cl, byte [sector_block_conv]
    push ecx
    push dword [ebp + 12]
    push dword [ebp + 8]
    call __ashldi3
    add esp, 12

;    xor ecx, ecx
;    mov cl, byte [sector_block_conv]
;    mov eax, dword [ebp + 8]
;    mov edx, dword [ebp + 12]
;.shift_loop
;    shl edx, 1
;    shl eax, 1
;    adc edx, 0
;    add cl, 1
;    cmp cl, byte [sector_block_conv]
;    jl .shift_loop

    ; Add boot partition start offset
    add eax, dword [boot_partition + _boot_partition.lba_start]
    adc edx, 0

    pop ebx
    pop ebp
    ret

; Hopefully buf is word aligned
ext4_read_block: ; int ext4_read_block(uint32_t block_low, uint32_t block_high, uint8_t *buf)
    push ebp
    mov ebp, esp
    push edi
    push esi

    ; buf
    mov esi, dword [ebp + 16]

    ; Convert block address to LBA. Who knows what happens with block addresses that convert
    ; to LBA > 48-bits
    push dword [ebp + 12]
    push dword [ebp + 8]
    call ext4_block_to_lba
    add esp, 8
    push eax ; lba low = dword [ebp - 12]
    push edx ; lba high = dword [ebp - 16]

    ; Get the number of times we have to read sectors
    mov eax, 1
    mov cl, byte [sector_block_conv]
    shl eax, cl

    push eax ; dword [ebp - 20]
    xor ecx, ecx
.sector_read_loop:
    push ecx ; Save ecx
    push dword [ebp - 16] ; LBA high
    push dword [ebp - 12] ; LBA low
    push esi ; sector buffer
    push dword [ahci_boot_device_port] ; port
    call ahci_port_read_sector
    add esp, 16
    pop ecx

    add dword [ebp - 12], 1
    adc dword [ebp - 16], 0
    add esi, DISK_SECTOR_SIZE
    add ecx, 1
    cmp ecx, dword [ebp - 20]
    jl .sector_read_loop
    add esp, 4

    xor eax, eax

    add esp, 8
    pop esi
    pop edi
    pop ebp
    ret

ext4_print_dir_entry: ; void ext4_print_dir_entry(struct ext4_dir_entry *dirent)
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov esi, dword [ebp + 8]
    mov edi, fname_buf

    xor ecx, ecx
    mov cl, byte [esi + _ext4_dir_entry.name_len]
    mov byte [edi + ecx + 1], 0
    lea eax, byte [esi + _ext4_dir_entry.name]
    push ecx
    push eax
    push edi
    call memcpy
    add esp, 12

    ; "inode: "
    push color_norm
    push .str1
    call print_str
    add esp, 8
    ; "0x%08X"
    push dword [esi + _ext4_dir_entry.inode]
    push number_string
    call itoa
    add esp, 8
    push color_norm
    push number_string
    call print_str
    add esp, 8
    ; " name: "
    push color_norm
    push .str2
    call print_str
    add esp, 8
    ; "%s"
    push color_norm
    push edi
    call print_str
    add esp, 8
    ; "\n"
    call print_newline

    pop edi
    pop esi
    pop ebp
    ret
.str1: db "inode: ", 0
.str2: db " name: ", 0
