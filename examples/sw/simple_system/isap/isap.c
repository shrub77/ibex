#include "api.h"
#include "isap.h"
#include "ascon.h"

const unsigned char ISAP_IV_A[] = {0x01,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};
const unsigned char ISAP_IV_KA[] = {0x02,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};
const unsigned char ISAP_IV_KE[] = {0x03,ISAP_K,ISAP_rH,ISAP_rB,ISAP_sH,ISAP_sB,ISAP_sE,ISAP_sK};



/******************************************************************************/
/*                                   IsapRk                                   */
/******************************************************************************/

void isap_rk(
	const unsigned char *k,
	const unsigned char *iv,
	const unsigned char *in,
	const unsigned long long inlen,
	unsigned char *out,
	const unsigned long long outlen
){
	// Init State
	state_t state;
	init_state(&state, ISAP_STATE_SZ);
	add_bytes(&state,k,0,CRYPTO_KEYBYTES);
	add_bytes(&state,iv,CRYPTO_KEYBYTES,ISAP_IV_SZ);
	ascon_p12(&state); //ISAP_sK
    
	// Absorb
	for (size_t i = 0; i < inlen*8-1; i++){
		size_t cur_byte_pos = i/8;
		size_t cur_bit_pos = 7-(i%8);
		unsigned char cur_bit = ((in[cur_byte_pos] >> (cur_bit_pos)) & 0x01) << 7;
		add_bytes(&state,(const unsigned char*)&cur_bit,0,1);
		ascon_p1(&state);
	}
	unsigned char cur_bit = ((in[inlen-1]) & 0x01) << 7;
	add_bytes(&state,(const unsigned char*)&cur_bit,0,1);
	ascon_p12(&state);

	extract_bytes(&state, out, 0, outlen);

}

/******************************************************************************/
/*                                  IsapMac                                   */
/******************************************************************************/

void isap_mac(
	const unsigned char *k,
	const unsigned char *npub,
	const unsigned char *ad, const unsigned long long adlen,
	const unsigned char *c, const unsigned long long clen,
	unsigned char *tag
){
	// Init State
	state_t state;
	init_state(&state, ISAP_STATE_SZ);
	add_bytes(&state,npub,0,CRYPTO_NPUBBYTES);

	add_bytes(&state,ISAP_IV_A,CRYPTO_NPUBBYTES,ISAP_IV_SZ);

	ascon_p12(&state);

	// Absorb AD
	size_t rate_bytes_avail = ISAP_rH_SZ;
	unsigned char cur_ad;
	for (unsigned long long i = 0; i < adlen; i++){
		if(rate_bytes_avail == 0){
			ascon_p12(&state);
			rate_bytes_avail = ISAP_rH_SZ;
		}
		cur_ad = ad[i];
		add_bytes(&state,&cur_ad,ISAP_rH_SZ-rate_bytes_avail,1);
		rate_bytes_avail--;
	}

	// Absorb Padding: 0x80
	if(rate_bytes_avail == 0){
		ascon_p12(&state);
		rate_bytes_avail = ISAP_rH_SZ;
	}
	unsigned char pad = 0x80;
	add_bytes(&state,&pad,ISAP_rH_SZ-rate_bytes_avail,1);
	ascon_p12(&state);

	// Domain Seperation: 0x01
	unsigned char dom_sep = 0x01;
	add_bytes(&state,&dom_sep,ISAP_STATE_SZ-1,1);

	// Absorb C
	rate_bytes_avail = ISAP_rH_SZ;
	unsigned char cur_c;
	for (unsigned long long i = 0; i < clen; i++){
		cur_c = c[i];
		add_bytes(&state,&cur_c,ISAP_rH_SZ-rate_bytes_avail,1);
		rate_bytes_avail--;
		if(rate_bytes_avail == 0){
			ascon_p12(&state);
			rate_bytes_avail = ISAP_rH_SZ;
		}
	}

	// Absorb Padding: 0x80
	pad = 0x80;
	add_bytes(&state,&pad,ISAP_rH_SZ-rate_bytes_avail,1);
	ascon_p12(&state);

	// Derive Ka*
	unsigned char y[CRYPTO_KEYBYTES];
	unsigned char ka_star[CRYPTO_KEYBYTES];
	extract_bytes(&state, y, 0, CRYPTO_KEYBYTES);
	
	isap_rk(k,ISAP_IV_KA,y,CRYPTO_KEYBYTES,ka_star,CRYPTO_KEYBYTES);
	
	// Squeezing Tag
	overwrite_bytes(&state, ka_star, 0, CRYPTO_KEYBYTES);
	ascon_p12(&state);
	extract_bytes(&state, tag, 0, CRYPTO_KEYBYTES);
}

/******************************************************************************/
/*                                  IsapEnc                                   */
/******************************************************************************/

void isap_enc(
	const unsigned char *k,
	const unsigned char *npub,
	const unsigned char *m, const unsigned long long mlen,
	unsigned char *c
){
	// Derive Ke*
//	unsigned char state[ISAP_STATE_SZ];
    state_t state;
	isap_rk(k,ISAP_IV_KE,npub,CRYPTO_NPUBBYTES,state.bytes,ISAP_STATE_SZ-CRYPTO_NPUBBYTES);
	overwrite_bytes(&state,npub,ISAP_STATE_SZ-CRYPTO_NPUBBYTES,
	CRYPTO_NPUBBYTES);

	// Squeeze Keystream
	size_t key_bytes_avail = 0;
	for (unsigned long long i = 0; i < mlen; i++) {
		if(key_bytes_avail == 0){
			ascon_p6(&state);
			key_bytes_avail = ISAP_rH_SZ;
		}
	
		c[i] = m[i] ^ state.bytes[i%ISAP_rH_SZ];
		
		key_bytes_avail--;
	}
}
