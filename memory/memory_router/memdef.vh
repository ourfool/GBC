/***************************************************/
/* Address Map Definitions                         */
/***************************************************/

/*Cartridge has a total of 32 kB
 *address space*/
`define CARTRIDGE_LO 'h0000
`define CARTRIDGE_HI 'h7fff

`define EXTERNAL_EXPANSION_LO 'hA000
`define EXTERNAL_EXPANSION_HI 'hBFFF

/*LCD RAM has a total of 32 KB of address
 *space which is separated into 2 banks,
 *specified by the VBK register*/
`define LCDRAM_LO 'h8000
`define LCDRAM_HI 'h9FFF

/*Working ram has a total of 32 kB of
 * working memory, separated into
 *8 separate banks.  Bank0 is always
 * accessible by the address range
 * 0xC000 - 0xCFFF, but bank 0-7 are
 * accessible through 0xD000-0xDFFF
 * such that the bank being written
 * to is specified in the SVBK reg*/
`define WRAM_LO 'hC000
`define WRAM_HI 'hDFFF

`define ECHO_LO 'hE000
`define ECHO_HI 'hFDFF

/*OAM is composed of 160 bytes of
 *information*/
`define OAM_LO 'hFE00
`define OAM_HI 'hFE9F

/*The "little working RAM"  is
 *composed of 127 bytes of information
 */
`define LWRAM_LO 'hFF80
`define LWRAM_HI 'hFFFE

/* The IO register address space*/
`define IOREG_LO 'hFF00
`define IOREG_HI 'hFF7F

/* Definition to where the
 * interrupt enable register
 * is*/
`define IE_REGISTER 'hFFFF

/***************************************************/
/* IO Register Address Definitions                 */
/***************************************************/


/*io register            has been implemented? */
`define P1    16'hFF00   // X
`define SB    16'hFF01   // X
`define SC    16'hFF02   // X
`define DIV   16'hFF04   // X
`define TIMA  16'hFF05   // X
`define TMA   16'hFF06   // X
`define TAC   16'hFF07   // X
`define KEY1  16'hFF4D   // X
`define RP    16'hFF56   // X
`define VBK   16'hFF4F   // X
`define SVBK  16'hFF70   // X
`define IF    16'hFF0F   // X
`define IE    16'hFFFF   // X
`define IME   0
`define LCDC  16'hFF40   // X
`define STAT  16'hFF41   // X   
`define SCY   16'hFF42   // X
`define SCX   16'hFF43   // X
`define LY    16'hFF44   // X
`define LYC   16'hFF45   // X
`define DMA   16'hFF46   // X
`define BGP   16'hFF47   // X
`define OBP0  16'hFF48   // X
`define OBP1  16'hFF49   // X
`define WY    16'hFF4A   // X
`define WX    16'hFF4B   // X
`define HDMA1 16'hFF51   // X
`define HDMA2 16'hFF52   // X
`define HDMA3 16'hFF53   // X
`define HDMA4 16'hFF54   // X
`define HDMA5 16'hFF55   // X
`define BCPS  16'hFF68   // X
`define BCPD  16'hFF69   // X
`define OCPS  16'hFF6A   // X
`define OCPD  16'hFF6B   // X

`define NR10  16'hFF10   // X
`define NR11  16'hFF11   // X
`define NR12  16'hFF12   // X
`define NR13  16'hFF13   // X
`define NR14  16'hFF14   // X
`define NR21  16'hFF16   // X
`define NR22  16'hFF17   // X
`define NR23  16'hFF18   // X
`define NR24  16'hFF19   // X
`define NR30  16'hFF1A   // X
`define NR31  16'hFF1B   // X
`define NR32  16'hFF1C   // X
`define NR33  16'hFF1D   // X
`define NR34  16'hFF1E   // X
`define NR41  16'hFF20   // X
`define NR42  16'hFF21   // X
`define NR43  16'hFF22   // X
`define NR44  16'hFF23   // X
`define NR50  16'hFF24   // X
`define NR51  16'hFF25   // X
`define NR52  16'hFF26   // X
