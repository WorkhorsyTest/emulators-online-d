// Copyright (c) 2015-2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Copyright (c) 2008-2011, Kenneth Bell https://discutils.codeplex.com
// A module for reading DVD ISOs (Universal Disk Format) with D
// It uses a MIT style license
// It is hosted at: https://github.com/workhorsy/emulators-online-d
//
// See ECMA-167 and OSTA Universal Disk Format for details:
// http://en.wikipedia.org/wiki/Universal_Disk_Format
// https://sites.google.com/site/udfintro/
// http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// http://www.osta.org/specs/pdf/udf260.pdf
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module read_udf;

import std.stdio : File, stdout;
import std.stdint;
import std.string;
import std.conv;

immutable int MAX_INT = int.max;
immutable int HEADER_SIZE = 1024 * 32;
immutable int SECTOR_SIZE = 1024 * 2; // FIXME: This should not be hard coded

// FIXME: Temp classes
class Partition {}
interface IBuffer {}

// FIXME: Replace these with std.bitmanip
uint8_t to_uint8(ubyte[] buffer, int start = 0) {
	return buffer[start .. start + 1][0];
}

uint16_t to_uint16(ubyte[] buffer, int start = 0) {
	uint16_t left = ((to_uint8(buffer, start + 1) << 8) & 0xFF00);
	uint16_t right = ((to_uint8(buffer, start + 0) << 0) & 0x00FF);
	return (left | right);
}

uint32_t to_uint32(ubyte[] buffer, int start = 0) {
	uint32_t a = ((to_uint8(buffer, start + 3) << 24) & 0xFF000000);
	uint32_t b = ((to_uint8(buffer, start + 2) << 16) & 0x00FF0000);
	uint32_t c = ((to_uint8(buffer, start + 1) << 8) & 0x0000FF00);
	uint32_t d = ((to_uint8(buffer, start + 0) << 0) & 0x000000FF);
	return (a | b | c | d);
}

uint64_t to_uint64(ubyte[] buffer, int start = 0) {
	import std.system : Endian;
	import std.bitmanip : peek;
	return peek!(uint64_t, Endian.bigEndian)(buffer, start);
/*
	uint64_t a = ((to_uint8(buffer, start + 7) << 56) & 0xFF00000000000000);
	uint64_t b = ((to_uint8(buffer, start + 6) << 48) & 0x00FF000000000000);
	uint64_t c = ((to_uint8(buffer, start + 5) << 40) & 0x0000FF0000000000);
	uint64_t d = ((to_uint8(buffer, start + 4) << 32) & 0x000000FF00000000);
	uint64_t e = ((to_uint8(buffer, start + 3) << 24) & 0x00000000FF000000);
	uint64_t f = ((to_uint8(buffer, start + 2) << 16) & 0x0000000000FF0000);
	uint64_t g = ((to_uint8(buffer, start + 1) << 8) & 0x000000000000FF00);
	uint64_t h = ((to_uint8(buffer, start + 0) << 0) & 0x00000000000000FF);
	return (a | b | c | d | e | f | g | h);
*/
}

T round_up(T)(T value, int unit) {
	return (value + (unit - 1)); // unit) * unit
}

dstring to_dstring(ubyte[] buffer, int offset, int count) {
	auto byte_len = to_uint8(buffer, offset + count - 1);
	return to_dchars(buffer, offset, byte_len);
}

dstring to_dchars(ubyte[] buffer, int offset, int count) {
	if (count == 0) {
		return [];
	}

	uint8_t alg = to_uint8(buffer, offset);

	if (alg == 8.to!uint8_t || alg == 16.to!uint8_t) {
		throw new Exception("Corrupt compressed unicode string");
	}

	ubyte[] result;

	int pos = 1;
	while (pos < count) {
		uint8_t ch = to_uint8(['\0']);

		if (alg == 16) {
			ch = cast(uint8_t) (to_uint8(buffer, offset + pos) << 8);
			pos += 1;
		}

		if (pos < count) {
			ch |= to_uint8(buffer, offset + pos);
			pos += 1;
		}

		result ~= ch;
	}

	// Convert from ints to chars
	// FIXME: result = [bytes(chr(n), 'utf-8') for n in result];

	return cast(dstring) result;
}


class BaseTag {
	int _size;

	this(int size, ubyte[] buffer, int start) {
		this._size = size;

		this._assert_size(buffer, start);
	}

	int size() {
		return this._size;
	}

	// Make sure there is enough space
	void _assert_size(ubyte[] buffer, int start) {
/*
		// Just return if the size is zero
		if (this._size == 0) {
			return;
		}

		if (buffer.length - start < this._size) {
			throw new Exception("%s requires %s bytes, but buffer only has %s".format(typeof(this).stringof, this._size, buffer.length - start));
		}
*/
	}

	// Make sure the checksums match
	void _assert_checksum(ubyte[] buffer, int start, int expected_checksum) {
/*
		int checksum = 0;
		for (int i=0; i<16; ++i) {
			if (i == 4) {
				continue;
			}

			checksum += to_uint8(buffer, start + i);
		}

		// Truncate int to uint8
		//b = checksum;
		while (checksum >= 256) {
			checksum -= 256;
		}

		if (! checksum == expected_checksum) {
			throw new Exception("Checksum was %s, but %s was expected".format(checksum, expected_checksum));
		}
*/
	}

	// Make sure it is the correct type of tag
	void _assert_tag_identifier(int expected_tag_identifier) {
/*
		if (! this.descriptor_tag.tag_identifier == expected_tag_identifier) {
			throw new Exception("Expected Tag Identifier %s, but was %s".format(expected_tag_identifier, this.descriptor_tag.tag_identifier));
		}
*/
	}

	// Make sure the reserved space is all zeros
	void _assert_reserve_space(ubyte[] buffer, int start, int length) {
/*
		buf_seg = buffer[start .. start + length];
		for (int i=0; i<buf_seg.length; ++i) {
			n = buf_seg[i .. i + 1];
			if (! to_uint8(n) == 0) {
				throw new Exception("Reserve space at %s was not zero.".format(start));
			}
		}
*/
	}
}

class UdfContext {
	public LogicalPartition[] logical_partitions;
	public PhysicalPartition[ushort] physical_partitions;
	public int physical_sector_size;
	public File file;

	void UdfContext(ref File file, int physical_sector_size) {
		this.file = file;
		//this.logical_partitions = [];
		//this.physical_partitions = {};
		this.physical_sector_size = physical_sector_size;
	}
}


// "2.1.5 Entity Identifier" of http://www.osta.org/specs/pdf/udf260.pdf
enum EntityIdType {
	Unknown = 0,
	DomainIdentifier = 1,
	UDFIdentifier = 2,
	ImplementationIdentifier = 3,
	ApplicationIdentifier = 4,
}


// page 14 of http://www.osta.org/specs/pdf/udf260.pdf
// 1/12 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class EntityID : BaseTag {
	EntityIdType entity_id_type;
	uint8_t flags;
	ubyte[] identifier;
	ubyte[] identifier_suffix;

	this(EntityIdType entity_id_type, ubyte[] buffer, int start) {
		super(32, buffer, start);

		this.entity_id_type = entity_id_type;
		this.flags = to_uint8(buffer, start + 0);
		this.identifier = buffer[start + 1 .. start + 24];
		this.identifier_suffix = buffer[start + 24 .. start + 32];

		// Make sure the flag is always 0
		//if this.flags != 0:
		//	raise Exception("EntityID flags was not zero")
	}
}


// page 3/4 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// page 4/4 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
enum TagIdentifier {
	unknown = 0,
	PrimaryVolumeDescriptor = 1,
	AnchorVolumeDescriptorPointer = 2,
	VolumeDescriptorPointer = 3,
	ImplementationUseVolumeDescriptor = 4,
	PartitionDescriptor = 5,
	LogicalVolumeDescriptor = 6,
	UnallocatedSpaceDescriptor = 7,
	TerminatingDescriptor = 8,
	LogicalVolumeIntegrityDescriptor = 9,
	FileSetDescriptor = 256,
	FileIdentifierDescriptor = 257,
	FileEntry = 261,
}


// page 3/3 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// page 20 of http://www.osta.org/specs/pdf/udf260.pdf
class DescriptorTag : BaseTag {
	public ushort descriptor_crc;
	public ushort descriptor_crc_length;
	public ushort descriptor_version;
	public byte tag_check_sum;
	public TagIdentifier tag_identifier;
	public uint tag_location;
	public ushort tag_serial_number;

	this(ubyte[] buffer, int start = 0) {
		super(16, buffer, start);

		this.tag_identifier = cast(TagIdentifier) to_uint16(buffer, start + 0);
		this.descriptor_version = to_uint16(buffer, start + 2);
		this.tag_check_sum = to_uint8(buffer, start + 4);
		this.reserved = to_uint8(buffer, start + 5);
		this.tag_serial_number = to_uint16(buffer, start + 6);
		this.descriptor_crc = to_uint16(buffer, start + 8);
		this.descriptor_crc_length = to_uint16(buffer, start + 10);
		this.tag_location = to_uint32(buffer, start + 12);

		// Make sure the identifier is known
		if (this.tag_identifier == TagIdentifier.unknown) {
			throw new Exception("Tag Identifier was unknown");
		}

		this._assert_checksum(buffer, start, this.tag_check_sum);
		this._assert_reserve_space(buffer, start + 5, 1);
	}
}


// page 3/3 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class ExtentDescriptor : BaseTag {
	uint extent_length;
	uint extent_location;

	this(ubyte[] buffer, int start = 0) {
		super(8, buffer, start);

		this.extent_length = to_uint32(buffer, start);
		this.extent_location = to_uint32(buffer, start + 4);
	}
}


// page 3/15 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class AnchorVolumeDescriptorPointer : BaseTag {
	public ExtentDescriptor main_volume_descriptor_sequence_extent;
	public ExtentDescriptor reserve_volume_descriptor_sequence_extent;

	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.AnchorVolumeDescriptorPointer);

		this.main_volume_descriptor_sequence_extent = new ExtentDescriptor(buffer, start + 16);
		this.reserve_volume_descriptor_sequence_extent = new ExtentDescriptor(buffer, start + 24);
		this.reserved = buffer[start + 32 .. start + 512];

		this._assert_reserve_space(buffer, start + 32, 480);
	}
}


class PhysicalPartition {
	File _file;
	int _start;
	int _length;

	this(File file, int start, int length) {
		this._file = file;
		this._start = start;
		this._length = length;
	}
}


class LogicalPartition {
	UdfContext context;
	LogicalPartition volume_descriptor;

	this(UdfContext context, LogicalVolumeDescriptor volume_descriptor) {
		this.context = context;
		this.volume_descriptor = volume_descriptor;
	}

	void logical_block_size() {
		return this._volume_descriptor.logical_block_size;
	}

	static void from_descriptor(UdfContext context, LogicalVolumeDescriptor volume_descriptor, int index) {
		PartitionMap map = volume_descriptor.partition_maps[index];

		Type1PartitionMap asType1 = cast(Type1PartitionMap) map;
		if (asType1 !is null) {
			return Type1Partition(context, volume_descriptor, asType1);
		} else {
			throw new Exception("Unrecognised type of partition map %s".format(typeof(map)));
		}
	}
}


class Type1Partition : LogicalPartition {
	private Type1PartitionMap _partitionMap;
	private PhysicalPartition _physical;

	this(UdfContext context, LogicalVolumeDescriptor volume_descriptor, Type1PartitionMap partition_map) {
		super(context, volume_descriptor);
		_partitionMap = partition_map;
		_physical = context.physical_partitions[_partitionMap.partition_number];
	}

	int logical_block_size() {
		return this.volume_descriptor.logical_block_size;
	}
}


// page 4/17 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class FileSetDescriptor : BaseTag {
	public string abstract_file_identifier;
	public uint character_set_list;
	public string copyright_file_identifier;
	public DescriptorTag descriptor_tag;
	public EntityID/*DomainEntityIdentifier*/ domain_identifier;
	//public CharacterSetSpecification file_set_charset;
	public uint file_set_descriptor_number;
	public string file_set_identifier;
	public uint file_set_number;
	public ushort interchange_level;
	public string logical_volume_identifier;
	//public CharacterSetSpecification logical_volume_identifier_charset;
	public uint maximum_character_set_list;
	public ushort maximum_interchange_level;
	public LongAllocationDescriptor next_extent;
	//public DateTime recording_time;
	public LongAllocationDescriptor root_directory_icb;
	public LongAllocationDescriptor system_stream_directory_icb;

	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.FileSetDescriptor);

		this.recording_date_and_time = buffer[start + 16 .. start + 28]; // FIXME: timestamp
		this.interchange_level = to_uint16(buffer, start + 28);
		this.maximum_interchange_level = to_uint16(buffer, start + 30);
		this.character_set_list = to_uint32(buffer, start + 32);
		this.maximum_character_set_list = to_uint32(buffer, start + 36);
		this.file_set_number = to_uint32(buffer, start + 40);
		this.file_set_descriptor_number = to_uint32(buffer, start + 44);
		this.logical_volume_identifier_character_set = buffer[start + 48 .. start + 112]; // FIXME: charspec
		this.logical_volume_identifier = to_dstring(buffer, start + 112, 128);
		this.file_set_character_set = buffer[start + 240 .. start + 274]; // FIXME: charspec
		this.file_set_identifier = to_dstring(buffer, start + 304, 32);
		this.copyright_file_identifier = to_dstring(buffer, start + 336, 32);
		this.abstract_file_identifier = to_dstring(buffer, start + 368, 32);
		this.root_directory_icb = LongAllocationDescriptor(buffer, start + 400);
		this.domain_identifier = EntityID(EntityIdType.DomainIdentifier, buffer, start + 416);
		this.next_extent = LongAllocationDescriptor(buffer, start + 448);
		this.system_stream_directory_icb = LongAllocationDescriptor(buffer, start + 464);
		this.reserved = buffer[start + 480 .. start + 512];

		this._assert_reserve_space(buffer, start + 480, 32);
	}
}


// page 3/12 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class PrimaryVolumeDescriptor : BaseTag {
	public EntityIdentifier application_identifier;
	public uint CharacterSetList;
	public CharacterSetSpecification DescriptorCharSet;
	public CharacterSetSpecification ExplanatoryCharSet;
	public ushort Flags;
	public EntityIdentifier ImplementationIdentifier;
	public byte[] ImplementationUse;
	public ushort InterchangeLevel;
	public uint MaxCharacterSetList;
	public ushort MaxInterchangeLevel;
	public ushort MaxVolumeSquenceNumber;
	public uint PredecessorVolumeDescriptorSequenceLocation;
	public uint PrimaryVolumeDescriptorNumber;
	public DateTime RecordingTime;
	public ExtentDescriptor VolumeAbstractExtent;
	public ExtentDescriptor volume_copyright_notice_extent;
	public uint volume_descriptor_sequence_number;
	public string volume_identifier;
	public ushort volume_sequence_number;
	public string volume_set_identifier;

	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.PrimaryVolumeDescriptor);

		this.volume_descriptor_sequence_number = to_uint32(buffer, start + 16);
		this.primary_volume_descriptor_number = to_uint32(buffer, start + 20);
		this.volume_identifier = to_dstring(buffer, start + 24, 32);
		this.volume_sequence_number = to_uint16(buffer, start + 56);
		this.maximum_volume_sequence_number = to_uint16(buffer, start + 58);
		this.interchange_level = to_uint16(buffer, start + 60);
		this.maximum_interchange_level = to_uint16(buffer, start + 62);
		this.character_set_list = to_uint32(buffer, start + 64);
		this.maximum_character_set_list = to_uint32(buffer, start + 68);
		this.volume_set_identifier = to_dstring(buffer, start + 72, 128);
		this.descriptor_character_set = buffer[start + 200 .. start + 264]; // FIXME: char spec
		this.expalnatory_character_set = buffer[start + 264 .. start + 328]; // FIXME: char spec
		this.volume_abstract = ExtentDescriptor(buffer, start + 328);
		this.volume_copyright_notice = ExtentDescriptor(buffer, start + 336);
		this.application_identifier = EntityID(EntityIdType.ApplicationIdentifier, buffer, start + 344);
		this.recording_date_and_time = buffer[start + 376 .. start + 388]; // FIXME: timestamp
		this.implementation_identifier = EntityID(EntityIdType.ImplementationIdentifier, buffer, start + 388);
		this.implementation_use = buffer[start + 420 .. start + 484];
		this.predecessor_volume_descriptor_sequence_location = to_uint32(buffer, start + 484);
		this.flags = to_uint16(buffer, start + 488);
		this.reserved = buffer[start + 490 .. start + 512];

		this._assert_reserve_space(buffer, start + 490, 22);
	}
}


// page 3/17 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// page 45 of http://www.osta.org/specs/pdf/udf260.pdf
class PartitionDescriptor : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.PartitionDescriptor);

		this.volume_descriptor_sequence_number = to_uint32(buffer, start + 16);
		this.partition_flags = to_uint16(buffer, start + 20);
		this.partition_number = to_uint16(buffer, start + 22);
		this.partition_contents = EntityID(EntityIdType.UDFIdentifier, buffer, start + 24);
		this.partition_contents_use = buffer[start + 56 .. start + 184];
		this.access_type = to_uint32(buffer, start + 184);
		this.partition_starting_location = to_uint32(buffer, start + 188);
		this.partition_length = to_uint32(buffer, start + 192);
		this.implementation_identifier = EntityID(EntityIdType.ImplementationIdentifier, buffer, start + 196);
		this.implementation_use = buffer[start + 228 .. start + 356];
		this.reserved = buffer[start + 356 .. start + 512];

		// If the partition has allocated volume space
		if (this.partition_flags == 1) {
		}

		this._assert_reserve_space(buffer, start + 356, 156);
	}
}


// page 3/19 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// page 24 of http://www.osta.org/specs/pdf/udf260.pdf
class LogicalVolumeDescriptor : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.LogicalVolumeDescriptor);

		this.volume_descriptor_sequence_number = to_uint32(buffer, start + 16);
		this.descriptor_character_set = buffer[start + 20 .. start + 84]; // FIXME: charspec
		this.logical_volume_identifier = to_dstring(buffer, start + 84, 128);
		this.logical_block_size = to_uint32(buffer, start + 212);
		this.domain_identifier = EntityID(EntityIdType.DomainIdentifier, buffer, start + 216);
		this.logical_volume_contents_use = buffer[start + 248 .. start + 264];
		this.map_table_length = to_uint32(buffer, start + 264);
		this.number_of_partition_maps = to_uint32(buffer, start + 268);
		this.implementation_identifier = EntityID(EntityIdType.ImplementationIdentifier, buffer, start + 272);
		this.implementation_use = buffer[start + 304 .. start + 432];
		this.integrity_sequence_extent = ExtentDescriptor(buffer, start + 432);
		this._raw_partition_maps = buffer[start + 440 .. start + 512];

		if (! "*OSTA UDF Compliant" in this.domain_identifier.identifier) {
			throw new Exception("Logical Volume is not OSTA compliant");
		}
	}

	// "10.6.13 Partition Maps (BP 440)" of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
	void partition_maps() {
		buffer = this._raw_partition_maps;
		retval = [];
		part_start = 0;
		foreach (i ; 0 .. this.number_of_partition_maps) {
			partition_type = to_uint8(buffer, part_start);
			partitioin = null;
			if (partition_type == 1) {
				partition = Type1PartitionMap(buffer, part_start);
			} else {
				throw new Exception("Unexpected partition type %s".format(partition_type));
			}

			retval.append(partition);
			part_start += partition.size;
		}

		return retval;
	}

	// "2.2.4.4 byte LogicalVolumeContentsUse[16]" of http://www.osta.org/specs/pdf/udf260.pdf
	void file_set_descriptor_location() {
		return LongAllocationDescriptor(this.logical_volume_contents_use);
	}
}


// page 60 of http://www.osta.org/specs/pdf/udf260.pdf
class LongAllocationDescriptor : BaseTag {
	uint extent_length;
	LogicalBlockAddress extent_location;
	ubyte[] implementation_use;

	this(ubyte[] buffer, int start = 0) {
		super(16, buffer, start);

		this.extent_length = to_uint32(buffer, start + 0);
		this.extent_location = LogicalBlockAddress(buffer, start + 4);
		this.implementation_use = buffer[start + 10 .. start + 16];
	}
}


// page 4/3 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class LogicalBlockAddress : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(6, buffer, start);
		this.logical_block_number = to_uint32(buffer, start + 0);
		this.partition_reference_number = to_uint16(buffer, start + 4);
	}
}


class TerminatingDescriptor : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(512, buffer, start);

	// FIXME: Add the rest
	}
}


// page 3/21 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class Type1PartitionMap : BaseTag {
	this(ubyte[] buffer, int start) {
		super(6, buffer, start);

		this.partition_map_type = to_uint8(buffer, start + 0);
		this.partition_map_length = to_uint8(buffer, start + 1);
		this.volume_sequence_number = to_uint16(buffer, start + 2);
		this.partition_number = to_uint16(buffer, start + 4);

		if (! this.partition_map_type == 1) {
			throw new Exception("Type 1 Partition Map Type was %s instead of 1.".format(this.partition_map_type));
		}

		if (! this.partition_map_length == this.size) {
			throw new Exception("Type 1 Partition Map Length was %s instead of %s.".format(this.partition_map_length, this.size));
		}
	}
}


// page 3/22 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class Type2PartitionMap : BaseTag {
	this(ubyte[] buffer, int start) {
		super(64, buffer, start);

		this.partition_map_type = to_uint8(buffer, start + 0);
		this.partition_map_length = to_uint8(buffer, start + 1);
		this.partition_type_identifier = EntityID(EntityIdType.UDFIdentifier, start + 4, start + 32);

		if (! this.partition_map_type == 2) {
			throw new Exception("Type 2 Partition Map Type was %s instead of 2.".format(this.partition_map_type));
		}

		if (! this.partition_map_length == this.size) {
			throw new Exception("Type 2 Partition Map Length was %s instead of %s.".format(this.partition_map_length, this.size));
		}
	}
}


// page 4/28 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// page 56 of http://www.osta.org/specs/pdf/udf260.pdf
class FileEntry : BaseTag {
	this(ubyte buffer, int start = 0) {
		super(300, buffer, start); // FIXME: How do we deal with this having a dynamic size?

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.FileEntry);

		this.icb_tag = ICBTag(buffer, start + 16);
		this.uid = to_uint32(buffer, start + 36);
		this.gid = to_uint32(buffer, start + 40);
		this.permissions = to_uint32(buffer, start + 44);
		this.file_link_count = to_uint16(buffer, start + 48);
		this.record_format = to_uint8(buffer, start + 50);
		this.record_display_attributes = to_uint8(buffer, start + 51);
		this.record_length = to_uint32(buffer, start + 52);
		this.information_length = to_uint64(buffer, start + 56);
		this.logical_blocks_recorded = to_uint64(buffer, start + 64);
		this.access_date_and_time = buffer[start + 72 .. start + 84]; // FIXME: timestamp
		this.modification_date_and_time = buffer[start + 84 .. start + 96]; // FIXME: timestamp
		this.attribute_date_and_time = buffer[start + 96 .. start + 108]; // FIXME: timestamp
		this.checkpoint = to_uint32(buffer, start + 108);
		this.extended_attribute_icb = LongAllocationDescriptor(buffer, start + 112);
		this.implementation_identifier = EntityID(EntityIdType.ImplementationIdentifier, buffer, start + 128);
		this.uinque_id = to_uint64(buffer, start + 160);
		this.length_of_extended_attributes = to_uint32(buffer, start + 168);
		this.length_of_allocation_descriptors = to_uint32(buffer, start + 173);
		this.extended_attributes = buffer[start + 176 .. start + 176 + this.length_of_extended_attributes];
		this.allocation_descriptors = buffer[start + 176 + this.length_of_extended_attributes .. start + 176 + this.length_of_extended_attributes + this.length_of_allocation_descriptors];
	}
}


// page 4/25 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
enum FileType {
	unknown = 0,
	unallocated_space_entry = 1,
	partition_integrity_entry = 2,
	indirect_entry = 3,
	directory = 4,
	sequence_of_bytes = 5,
	block_special_device_file = 6,
	character_special_device_file = 7,
	recording_extended_attributes = 8,
	fifo = 9,
	c_issock = 10,
	terminal_entry = 11,
	symbolic_link = 12,
	stream_directory = 13,
}


// page 4/23 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
// "2.3.5 ICB Tag" of http://www.osta.org/specs/pdf/udf260.pdf
class ICBTag : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(20, buffer, start);

		this.prior_recorded_number_of_direct_entries = to_uint32(buffer, start);
		this.strategy_type = to_uint16(buffer, start + 4);
		this.strategy_parameter = buffer[start + 6 .. start + 2];
		this.maximum_number_of_entries = to_uint16(buffer, start + 8);
		this.reserved = buffer[start + 10 .. start + 11];
		this.file_type = to_uint8(buffer, start + 11);
		this.parent_icb_location = LogicalBlockAddress(buffer, start + 12);
		raw_flags = to_uint16(buffer, start + 18);
		this.allocation_type = raw_flags & 0x3;
		this.flags = raw_flags & 0xFFFC;

		this._assert_reserve_space(buffer, start + 10, 1);
	}
}


class CookedExtent {
	public long file_content_offset;
	public int partition;
	public long start_pos;
	public long length;

	this(long file_content_offset, int partition, long start_pos, long length) {
		this.file_content_offset = file_content_offset;
		this.partition = partition;
		this.start_pos = start_pos;
		this.length = length;
	}
}


class ShortAllocationDescriptor : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(8, buffer, start);
		length = to_uint32(buffer, start);
		this.extent_location = to_uint32(buffer, start + 4);
		this.extent_length = length & 0x3FFFFFFF;
		this.flags = (length >> 30) & 0x3;
	}
}


enum AllocationType {
	short_descriptors = 0,
	long_descriptors = 1,
	extended_descriptors = 2,
	embedded = 3,
}

class FileContentBuffer : IBuffer {
	private uint block_size;
	private UdfContext context;
	private CookedExtent[] extents;
	private FileEntry file_entry;
	private Partition partition;

	this(UdfContext context, Partition partition, FileEntry file_entry, uint block_size) {
		this.context = context;
		this.partition = partition;
		this.file_entry = file_entry;
		this.block_size = block_size;
		this.extents = null;

		this.load_extents();
	}

	void load_extents() {
		this.extents = [];
		active_buffer = this.file_entry.allocation_descriptors;

		// Short descriptors
		alloc_type = this.file_entry.icb_tag.allocation_type;
		if (alloc_type == AllocationType.short_descriptors) {
			file_pos = 0;
			i = 0;
			while (i < len(active_buffer)) {
				sad = ShortAllocationDescriptor(active_buffer, i);
				if (sad.extent_length == 0) {
					break;
				}
				if (sad.flags != 0) {
					throw new Exception("Can't use extents that are not recorded and allocated.");
				}

				new_extent = CookedExtent(file_pos, MAX_INT, sad.extent_location * this.block_size, sad.extent_length);
				this.extents.append(new_extent);
				file_pos += sad.extent_length;
				i += sad.size;
			}
		} else if (alloc_type == AllocationType.embedded) {
			throw new Exception();
		} else if (alloc_type == AllocationType.long_descriptors) {
			throw new Exception();
		} else {
			throw new Exception("FIXME: Add support for allocation type %s".format(alloc_type));
		}
	}

	void capacity() {
		return this.file_entry.information_length;
	}

	ubyte[] read(long pos, int offset, int count) {
		ubyte[] buffer = [];
		if (this.file_entry.icb_tag.allocation_type == AllocationType.embedded) {
			src_buffer = this.file_entry.allocation_descriptors;
			if (pos > src_buffer.length) {
				return buffer;
			}

			to_copy = min(src_buffer.length - pos, count);
			buffer[offset .. offset + to_copy] = src_buffer[pos .. pos + to_copy];
			return buffer;
		} else {
			return this.read_from_extents(pos, offset, count);
		}
	}

	ubyte[] read_from_extents(long pos, int offset, int count) {
		total_to_read = min(this.capacity - pos, count);
		total_read = 0;
		ubyte[] buffer = [];

		while (total_read < total_to_read) {
			extent = this.find_extent(pos + total_read);

			extent_offset = (pos + total_read) - extent.file_content_offset;
			to_read = min(total_to_read - total_read, extent.length - extent_offset);

			part = null;
			if (extent.partition != MAX_INT) {
				part = this.logical_partitions[extent.partition];
			} else {
				part = this.partition;
			}

			new_pos = extent.start_pos + extent_offset + part.physical_partition._start;
			part.physical_partition._file.seek(new_pos);
			buffer = part.physical_partition._file.read(to_read);
			if (len(buffer) == 0) {
				return buffer;
			}

			total_read += len(buffer);
		}

		return buffer;
	}

	void find_extent(long pos) {
		foreach (extent ; this.extents) {
			if (extent.file_content_offset + extent.length > pos) {
				return extent;
			}
		}

		return null;
	}
}

// FIXME: Renamed from File
class UdfFile {
	protected uint block_size;
	protected IBuffer content;
	protected UdfContext context;
	protected FileEntry file_entry;
	protected Partition partition;

	this(UdfContext context, Partition partition, FileEntry file_entry, uint block_size) {
		this.context = context;
		this.partition = partition;
		this.file_entry = file_entry;
		this.block_size = block_size;
		this.content = null;
	}

	static UdfFile from_descriptor(UdfContext context, LongAllocationDescriptor icb) {
		partition = context.logical_partitions[icb.extent_location.partition_reference_number];
		root_data_dir = read_extent(context, icb);

		dt = DescriptorTag(root_data_dir);
		if (dt.tag_identifier == TagIdentifier.FileEntry) {
			file_entry = FileEntry(root_data_dir);
			if (file_entry.icb_tag.file_type == FileType.directory) {
				return Directory(context, partition, file_entry);
			} else {
				throw new Exception("FIXME: Expected a directory not a FileType of %s".format(file_entry.icb_tag.file_type));
			}
		} else {
			throw new Exception("FIXME: Add the code for handling Tag Identifier %s".format(dt.tag_identifier));
		}
	}

	IBuffer file_content() {
		if (this.content) {
			return this.content;
		}

		this.content = new FileContentBuffer(this.context, this.partition, this.file_entry, this.block_size);
		return this.content;
	}
}


enum FileCharacteristic {
	existence = 0x01,
	directory = 0x02,
	deleted = 0x04,
	parent = 0x08,
	metadata = 0x10,
}


// page 4/21 of http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-167.pdf
class FileIdentifierDescriptor : BaseTag {
	this(ubyte[] buffer, int start = 0) {
		super(0, buffer, start);

		this.rounded_size = 0;

		this.descriptor_tag = DescriptorTag(buffer, start);
		this._assert_tag_identifier(TagIdentifier.FileIdentifierDescriptor);

		this.file_version_number = to_uint16(buffer, start + 16);
		this.file_characteristics = to_uint8(buffer, start + 18);
		this.length_of_file_identifier = to_uint8(buffer, start + 19);
		this.ICB = LongAllocationDescriptor(buffer, start + 20);
		this.length_of_implementation_use = to_uint16(buffer, start + 36);
		this.implementation_use = buffer[start + 38 .. start + 38 + this.length_of_implementation_use];

		s = start + 38 + this.length_of_implementation_use;
		l = this.length_of_file_identifier;
		this.file_identifier = to_dchars(buffer, s, l);

		this.rounded_size = round_up(38 + this.length_of_implementation_use + this.length_of_file_identifier, 4);
	}
}


class Directory : UdfFile {
	this(UdfContext context, Partition partition, FileEntry file_entry) {
		super(context, partition, file_entry, partition.logical_block_size);
		if (this.file_content.capacity > MAX_INT) {
			throw new Exception("Directory too big");
		}

		this._entries = [];
		content_bytes = this.file_content.read(0, 0, this.file_content.capacity);

		pos = 0;
		while (pos < len(content_bytes)) {
			id = FileIdentifierDescriptor(content_bytes, int(pos));

			if ((id.file_characteristics & (FileCharacteristic.deleted | FileCharacteristic.parent)) == 0) {
				this._entries.append(id);
			}

			pos += id.rounded_size;
		}
	}

	void all_entries() {
		return this._entries;
	}
}


void read_extent(UdfContext context, LongAllocationDescriptor extent) {
	partition = context.logical_partitions[extent.extent_location.partition_reference_number];
	offset = partition.physical_partition._start;
	pos = extent.extent_location.logical_block_number * partition.logical_block_size;
	length = extent.extent_length;
	context.file.seek(offset + pos);
	retval = context.file.read(length);
	return retval;
}


// FIXME: This assumes the sector size is 2048
void is_valid_udf(ref File file, long file_size) {
	// Move to the start of the file
	file.seek(0);

	// Make sure there is enough space for a header and sector
	if (file_size < HEADER_SIZE + SECTOR_SIZE) {
		return false;
	}

	// Move past 32K of empty space
	file.seek(HEADER_SIZE);

	is_valid = true;
	has_bea, has_vsd, has_tea = false, false, false;

	// Look at each sector
	while (is_valid) {
		// Read the next sector
		buffer = file.read(SECTOR_SIZE);
		if (buffer.length < SECTOR_SIZE) {
			break;
		}

		// Get the sector meta data
		structure_type = to_uint8(buffer, 0);
		standard_identifier = buffer[1 .. 6];
		structure_version = to_uint8(buffer, 6);

		// Check if we have the beginning, middle, or end
		if (standard_identifier in ["BEA01"]) {
			has_bea = true;
		} else if (standard_identifier in ["NSR02", "NSR03"]) {
			has_vsd = true;
		} else if (standard_identifier in ["TEA01"]) {
			has_tea = true;
		} else if (standard_identifier in ["BOOT2", "CD001", "CDW02"]) {

		} else {
			is_valid = false;
		}
	}

	return has_bea && has_vsd && has_tea;
}

void get_sector_size(ref File file, long file_size) {
	long[] sizes = [4096, 2048, 1024, 512];
	foreach (size ; sizes) {
		// Skip this size if the file is too small for all the sectors
		if (file_size < 257 * size) {
			continue;
		}

		// Move to the last sector
		file.seek(256 * size);

		// Read the Descriptor Tag
		buffer = file.read(16);
		tag = null;
		try {
			tag = DescriptorTag(buffer);
		// Skip if the tag is not valid
		} catch (Throwable) {
			continue;
		}

		// Skip if the tag thinks it is at the wrong sector
		if (tag.tag_location != 256) {
			continue;
		}

		// Skip if the sector is not an Anchor Volume Description Pointer
		if (tag.tag_identifier != TagIdentifier.AnchorVolumeDescriptorPointer) {
			continue;
		}

		// Got the correct size
		return size;
	}

	throw new Exception("Could not get file sector size.");
}


void read_udf_file(string file_name) {
	import std.stdio : File;

	// Make sure the file exists
	if (! os.path.isfile(file_name)) {
		throw new Exception("No such file '%s'".format(file_name));
	}

	// Open the file
	auto f = File(file_name, "rb");
	scope (exit) f.close();

	long file_size = f.size();

	// Make sure the file is valid UDF
	if (! is_valid_udf(file, file_size)) {
		throw new Exception("Is not a valid UDF file '%s'".format(file_name));
	}

	// Make sure the file can fit all the sectors
	sector_size = get_sector_size(file, file_size);
	if (file_size < 257 * sector_size) {
		throw new Exception("File is too small to hold all sectors '%s'".format(file_name));
	}

	// "5.2 UDF Volume Structure and Mount Procedure" of https://sites.google.com/site/udfintro/
	// Read the Anchor VD Pointer
	context = UdfContext(file, sector_size);
	sector = 256;
	file.seek(sector * sector_size);
	buffer = file.read(512);
	tag = DescriptorTag(buffer[0 .. 16]);
	if (! tag.tag_identifier == TagIdentifier.AnchorVolumeDescriptorPointer) {
		throw new Exception("The last sector was supposed to be an Archive Volume Descriptor, but was not.");
	}
	avdp = AnchorVolumeDescriptorPointer(buffer);

	// Get the location of the primary volume descriptor
	pvd_sector = avdp.main_volume_descriptor_sequence_extent.extent_location;

	// Look through all the sectors and find the partition descriptor
	logical_volume_descriptor = null;
	terminating_descriptor = null;
	foreach (sector ; pvd_sector .. 257) {
		// Move to the sector start
		file.seek(sector * sector_size);

		// Read the Descriptor Tag
		buffer = file.read(16);
		tag = null;
		try {
			tag = DescriptorTag(buffer);
		// Skip if not valid
		} catch (Throwable) {
			continue;
		}

		// Move back to the start of the sector
		file.seek(sector * sector_size);
		buffer = file.read(512);

		if (tag.tag_identifier == TagIdentifier.PrimaryVolumeDescriptor) {
			desc = PrimaryVolumeDescriptor(buffer);
		} else if (tag.tag_identifier == TagIdentifier.AnchorVolumeDescriptorPointer) {
			anchor = AnchorVolumeDescriptorPointer(buffer);
		} else if (tag.tag_identifier == TagIdentifier.VolumeDescriptorPointer) {
			//VolumeDescriptorPointer(buffer);
		} else if (tag.tag_identifier == TagIdentifier.ImplementationUseVolumeDescriptor) {
			//ImplementationUseVolumeDescriptor(buffer);
		} else if (tag.tag_identifier == TagIdentifier.PartitionDescriptor) {
			partition_descriptor = PartitionDescriptor(buffer);
			start = partition_descriptor.partition_starting_location * sector_size;
			length = partition_descriptor.partition_length * sector_size;
			physical_partition = PhysicalPartition(file, start, length);
			context.physical_partitions[partition_descriptor.partition_number] = physical_partition;
		} else if (tag.tag_identifier == TagIdentifier.LogicalVolumeDescriptor) {
			logical_volume_descriptor = LogicalVolumeDescriptor(buffer);
		} else if (tag.tag_identifier == TagIdentifier.UnallocatedSpaceDescriptor) {
			//UnallocatedSpaceDescriptor(buffer);
		} else if (tag.tag_identifier == TagIdentifier.TerminatingDescriptor) {
			terminating_descriptor = TerminatingDescriptor(buffer);
		} else if (tag.tag_identifier == TagIdentifier.LogicalVolumeIntegrityDescriptor) {
			//LogicalVolumeIntegrityDescriptor(buffer);
		} else if (tag.tag_identifier != 0) {
			throw new Exception("Unexpected Descriptor Tag :%s".format(tag.tag_identifier));
		}

		if (logical_volume_descriptor && partition_descriptor && terminating_descriptor) {
			break;
		}
	}

	// Make sure we have all the segments we need
	if (! logical_volume_descriptor) {
		throw new Exception("File is missing a Logical Volume Descriptor sector.");
	}

	if (! partition_descriptor) {
		throw new Exception("File is missing a Partition Descriptor sector.");
	}

	if (! terminating_descriptor) {
		throw new Exception("File is missing a Terminating Descriptor sector.");
	}

	// Get all the logical partitions
	foreach (i ; 0 .. logical_volume_descriptor.partition_maps.length) {
		context.logical_partitions.append(LogicalPartition.from_descriptor(context, logical_volume_descriptor, i));
	}

	// Get the extent from the partition
	fsd_buffer = read_extent(context, logical_volume_descriptor.file_set_descriptor_location);

	tag = null;
	try {
		tag = DescriptorTag(fsd_buffer);
	} catch (Throwable) {
		throw new Exception("Failed to get Descriptor Tag from Partition Extent.");
	}

	// Get the root file information from the extent
	file_set_descriptor = FileSetDescriptor(fsd_buffer);
	root_directory = UdfFile.from_descriptor(context, file_set_descriptor.root_directory_icb);
	return root_directory;
}


int main() {
	// cde
	//stdout.writefln("abcdefghijklm"[2 .. 5]);
	return 0;
}
