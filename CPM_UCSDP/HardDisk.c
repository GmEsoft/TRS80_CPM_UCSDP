#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <stddef.h>
#include <string.h>

#include <fcntl.h>    // O_RDWR...
#include <sys/stat.h> // S_IWRITE

#define HARDDISK "Hard Disk Image Converter V0.1, (C) 2020 by GmEsoft"

#define TRACE 0

typedef unsigned int uint32_t;

void help()
{
	puts(
		"HardDisk -A|-C|-U|-X -I:infile [-O:outfile] [opts...]\n"
		"   -A          Analyze\n"
		"   -C          Create\n"
		"   -U          Update\n"
		"   -X          Extract\n"
		"   -I:infile   Input image file\n"								// infile
		"   -O:outfile  Output image file\n"							// outfile
		"opts:\n"
		"   -1          1st sector=1\n"									// psector1
		"   -T:nn       nn Tracks    (for  Create)  default 40\n"		// ptracks
		"               Start Track  (for Ext/Upd)  default  0\n"
		"   -S:nn       nn Sectors   (for  Create)  default 18\n"		// psectors
		"               Start Sector (for Ext/Upd)  default  0\n"
		"   -N:nn       nn Sectors   (for Ext/Upd)  default  0=all\n"	// pnsectors
	);
}

#define SEC_LEN 256

/*******************************************************

				Hard Disk format
				=================
000000-000100	Header
000100-.....	Sectors data (256 bytes)

*******************************************************/

unsigned char buf[SEC_LEN];

int sector0;
int tracks=0, sectors=0, sides=0;
int psector1=0, psides=1, ptracks=0, psectors=0, pnsectors=0;
int ptrack0=0, psector0=0;
int pbeghead=0, pendhead=-1, pheads, ptrksidorder=0;
int eofsector=-1;

int offset = 0x100;

/*
		DW		0CB56H			;00: magic number
		DB		10H				;02: format version 0x10
		DB		00H				;03: checksum-not used
		DW		0401H			;04: must be 0x401
		DB		0				;06: media type, 0 for hard disk
		DB		00H				;07: 0x80=write protected
		DB		1				;08: autoboot
		DW		4200H			;09: reserved - load address ?
		DB		2				;0B: OS type (2=CP/M, no patch by FreHD.ROM)
		ORG		001AH
		DB		0				;1A: heads/cyl (0:[sects/cyl]/32)
		DB		01H				;1B: cyls/disk (high 3 bits)
		DB		32H				;1C: cyls/disk (low  8 bits) - deflt=256
		DB		0C0H			;1D: sects/cyl
		DB		08H				;1E: grans/track (deprecated)
		DB		01H				;1F: directory cyl (deprecated)
		DB		'xtrshard'
		ORG		40H
		DB		'IPL'
*/

void padbuffer()
{
	const char *pad = " Padded sector. "; // 16 chars
	int j;

	for ( j=0; j<SEC_LEN; ++j )
	{
		buf[j] = pad[j & 0x0F];
	}

}

void getparams( int infile )
{
	int nbytes;

	lseek( infile, 0x000000, SEEK_SET );
	nbytes = read( infile, buf, SEC_LEN );

	if ( nbytes < SEC_LEN )
	{
		printf( "Failed to load HDV header\n" );
		exit( 1 );
	}

	offset = buf[4]<<8;
	sides = buf[0x1A];
	tracks = ( buf[0x1B] << 8 ) | buf[0x1C];
	sectors = buf[0x1D] ? buf[0x1D] : 0x100;

	printf( "header params: sides(heads)=%d, tracks(cyls)=%d, sectors(sects/cyl)=%d\n", sides, tracks, sectors );

	if ( sides )
	{
		sectors /= sides;
	}
	else
	{
		sides = sectors/32;
		sectors = 32;
	}

	if ( pendhead < 0 )
	{
		pendhead = sides - 1;
	}
	printf( "computed params: sides(heads)=%d, pendhead=%d, sectors(sects/trk)=%d\n", sides, pendhead, sectors );
}

void setparams()
{
	pheads = pendhead - pbeghead + 1;
#if TRACE
	printf( "ptrack0=%d psector0=%d psector1:=%d\n", ptrack0, psector0, psector1 );
#endif
	if ( psector0 )
		psector0 -= psector1;
	sector0 = ( ptrack0 * ( ptrksidorder ? ( sectors * sides ) : sectors ) + psector0 );
#if TRACE
	printf( "sector0=%d\n", sector0 );
#endif
	if ( !pnsectors ) {
		pnsectors = ( ptracks ? ptracks : tracks ) * sectors * pheads - sector0;
#if TRACE
		printf( "pnsectors=%d := ( ptracks=%d ? ptracks : tracks=%d ) * sectors=%d * pheads=%d - sector0=%d\n",
			pnsectors, ptracks, tracks, sectors, pheads, sector0 );
#endif
	}
	printf( "- setparams: pheads=%d psectors=%d sector0=%d pnsectors=%d ptracks=%d sectors=%d\n",
		pheads, psectors, sector0, pnsectors, ptracks ? ptracks : tracks, sectors );
}

int getvhdsec( int nsec )
{
	int trk, sec, sid;
	if ( ptrksidorder )
	{
		trk = nsec / ( sides * sectors );
		sec = nsec % ( sides * sectors );
		sid = sec / sectors;
	}
	else
	{
		sid = nsec / ( tracks * sectors );
		sec = nsec % ( tracks * sectors );
		trk = sec / sectors;
	}
	sec = ( sec + psector1 ) % sectors;
	printf( "T%d H%d S%d\t", trk, pbeghead + sid, sec );
	sec = ( trk * sides + pbeghead + sid ) * sectors + sec;
	return sec;
}

void analyze( int infile )
{
	long cylsize, headsize, datasize, filesize;

	getparams( infile );

	setparams();

	cylsize  = (long)sides * sectors * 0x100;
	headsize = (long)sectors * tracks * 0x100;
	datasize = (long)sides * sectors * tracks * 0x100;
	filesize = datasize + offset;

	if ( buf[0] == 0x56 && buf[1] == 0xCB )
	{
		printf( "Signature 56 CB found\n" );
	}
	else
	{
		printf( "Signature 56 CB *NOT* found\n" );
	}

	printf( "Version:        %d.%d\n", buf[2] >> 4, buf[2] & 0x0F );
	printf( "Offset:         %04X\n", offset );
	printf( "Heads:          %d\n", sides );
	printf( "Cylinders:      %d\n", tracks );
	printf( "Sec/Cylinder:   %d\n", sides * sectors );
	printf( "Sec/Track:      %d\n", sectors );
	printf( "Cylinder Size:  0x%08lX=%ld\n", cylsize,  cylsize );
	printf( "Head Size:      0x%08lX=%ld\n", headsize, headsize );
	printf( "Data Size:      0x%08lX=%ld\n", datasize, datasize );
	printf( "Data Size:      0x%08lX=%ld\n", datasize, datasize );
	printf( "Image Size:     0x%08lX=%ld\n", filesize, filesize );
	printf( "Volume Label:   %s\n", &buf[32] );
	printf( "Filename:       %s\n", &buf[64] );
}

void extract( int infile, int outfile )
{
	int i;

	getparams( infile );

	setparams();

	for ( i=sector0; i<sector0+pnsectors || !pnsectors; ++i )
	{
		int nbytes;
		int sec = getvhdsec( i );
		lseek( infile, offset + 0x100 * sec, SEEK_SET );

		nbytes = read( infile, buf, SEC_LEN );

#if TRACE
		printf("I:%d O:%d B:%d\t", i, offset + 0x100 * sec, nbytes );
#endif

		if ( nbytes < SEC_LEN )
		{
			padbuffer();
			if ( eofsector < 0 )
			{
				eofsector = i;
				printf( "Reading Past EOF\n" );
			}

			if (!pnsectors)
			{
				// Break if EOF and no limit on number of sectors
				write( outfile, buf, SEC_LEN );
				break;
			}
		}

		write( outfile, buf, SEC_LEN );
	}
	printf( "\n" );

}

void create( int infile, int outfile, int update )
{
	int i;

	if ( update )
	{
		getparams( outfile );
	}
	else
	{
		printf( "Create not implemented\n" );
		exit( 1 );
	}

	setparams();

	lseek( infile, 0, SEEK_SET );

	for ( i=sector0; i<sector0+pnsectors || !pnsectors; ++i )
	{
		int nbytes;
		int sec = getvhdsec( i );

		lseek( outfile, offset + 0x100 * sec, SEEK_SET );

		nbytes = read( infile, buf, SEC_LEN );

		if ( nbytes < SEC_LEN )
		{
			padbuffer();

			if ( eofsector < 0 )
			{
				eofsector = i;
				printf( "Reading Past EOF\n" );
			}

			if (!pnsectors)
			{
				// Break if EOF and no limit on number of sectors
				write( outfile, buf, SEC_LEN );
				break;
			}
		}

		write( outfile, buf, SEC_LEN );
	}
	printf( "\n" );
}

int main( int argc, char* argv[] )
{
	int infile=0, outfile=0;

	int	i;

	char command = 'A';
	char sub = 0;

	puts( HARDDISK "\n" );

	for ( i=1; i<argc; ++i )
	{
		char *s = argv[i];
		char c = 0;

		if ( *s == '-' )
			++s;
		switch ( toupper( *s ) )
		{
		case 'A':	// Analyze
		case 'C':	// Create
		case 'X':	// eXtract
		case 'U':	// Update
			command = toupper( *s );
			break;
		case 'I':	// Input file
			++s;
			if ( *s == ':' )
				++s;
			printf( "Reading: %s\n", s );
			infile = open( s, _O_RDONLY | _O_BINARY, _S_IREAD );
			break;
		case 'O':	// Output file
			++s;
			if ( *s == ':' )
				++s;
			if ( command == 'U' )
			{
				printf( "Updating: %s\n", s );
				outfile = open( s, _O_RDWR | _O_BINARY, _S_IWRITE );
			}
			else
			{
				printf( "Creating: %s\n", s );
				outfile = open( s, _O_CREAT | _O_TRUNC | _O_RDWR | _O_BINARY, _S_IWRITE );
			}
			break;
		case 'T':	// Number of tracks (cylinders)
			++s;
			if ( *s == ':' )
				++s;
			sscanf( s, "%d", &ptracks );
			break;
		case 'S':	// Number of sectors (create)
			++s;
			if ( *s == ':' )
				++s;
			sscanf( s, "%d", &psectors );
			break;
		case 'N':	// Number of sectors to transfer
			++s;
			if ( *s == ':' )
				++s;
			sscanf( s, "%d", &pnsectors );
			break;
		case 'H':	// Heads
			++s;
			if ( *s == ':' )
				++s;
			if ( *s == '*' )
				++s,ptrksidorder=1;
			if ( *s )
			{
				sscanf( s, "%d%c%d", &pbeghead, &sub, &pendhead );
				//printf( "%d %c %d\n", pbeghead, sub, pendhead );
				if ( pendhead<0 )
					pendhead = pbeghead;
			}
			break;
		case '1':
			psector1 = 1;
			break;
		case '?':
			help();
			return 0;
		default:
			printf( "Unrecognized switch: -%s\n", s );
			printf( "HardDisk -? for help.\n" );
			return 1;
		}

		if ( errno )
		{
			puts( strerror( errno ) );
			return 1;
		}
	}

	switch ( command )
	{
	case 'A':
		analyze( infile );
		break;
	case 'C':
		create( infile, outfile, 0 );
		break;
	case 'U':
		ptrack0 = ptracks;
		psector0 = psectors;
		ptracks = psectors = 0;
		create( infile, outfile, 1 );
		break;
	case 'X':
		ptrack0 = ptracks;
		psector0 = psectors;
		ptracks = psectors = 0;
		//analyze( infile );
		extract( infile, outfile );
		break;
	}

	if ( eofsector >= 0 )
		printf( "Warning: EOF encountered at sector %d\n", eofsector );

	if ( infile )
		close( infile );

	if ( outfile )
		close( outfile );


	return 0;
}
