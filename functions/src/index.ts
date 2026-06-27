import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Interface untuk request data
interface KlaimHewanRequest {
  uidTag: string;
}

// Interface untuk response data
interface KlaimHewanResponse {
  status: string;
  data?: any;
  message?: string;
}

/**
 * Cloud Function untuk mengklaim hewan peliharaan
 * Metode Keamanan: Hanya backend yang bisa mengupdate id_pemilik
 */
export const klaimHewan = functions.https.onCall(
  async (data: KlaimHewanRequest, context): Promise<KlaimHewanResponse> => {
    // Validasi autentikasi
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Pengguna harus login untuk mengklaim hewan.'
      );
    }

    const userId = context.auth.uid;
    const { uidTag } = data;

    // Validasi input
    if (!uidTag || typeof uidTag !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'UID Tag NFC harus berupa string yang valid.'
      );
    }

    const db = admin.firestore();
    const hewanRef = db.collection('master_hewan').doc(uidTag);

    try {
      // Gunakan transaksi untuk memastikan atomicity
      const result = await db.runTransaction(async (transaction) => {
        const hewanDoc = await transaction.get(hewanRef);

        // Pemeriksaan 1: Apakah tag NFC valid/terdaftar?
        if (!hewanDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Tag NFC ini tidak valid atau tidak terdaftar dalam sistem.'
          );
        }

        const hewanData = hewanDoc.data();
        
        // Pemeriksaan 2: Apakah hewan sudah diklaim?
        if (hewanData?.id_pemilik !== null && hewanData?.id_pemilik !== undefined) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Hewan ini sudah diklaim oleh pemain lain. Coba tag NFC yang berbeda.'
          );
        }

        // Logika Sukses: Klaim hewan untuk pengguna
        transaction.update(hewanRef, {
          'id_pemilik': userId
        });

        // Tambahkan timestamp klaim
        transaction.update(hewanRef, {
          'diklaim_pada': admin.firestore.FieldValue.serverTimestamp()
        });

        return hewanData;
      });

      // Log untuk monitoring
      console.log(`Hewan ${result?.nama_hewan} berhasil diklaim oleh user ${userId}`);

      return {
        status: 'sukses',
        data: result,
        message: `Selamat! Anda berhasil mendapatkan ${result?.nama_hewan}!`
      };

    } catch (error) {
      // Jika error sudah berupa HttpsError, lempar ulang
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Log error untuk debugging
      console.error('Error dalam klaimHewan:', error);

      // Error umum
      throw new functions.https.HttpsError(
        'internal',
        'Terjadi kesalahan internal. Silakan coba lagi.'
      );
    }
  }
);

/**
 * Cloud Function untuk mendapatkan statistik game (opsional)
 */
export const getGameStats = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Harus login');
    }

    const db = admin.firestore();
    
    try {
      const totalHewan = await db.collection('master_hewan').get();
      const hewanTerklaim = await db.collection('master_hewan')
        .where('id_pemilik', '!=', null)
        .get();

      return {
        total_hewan: totalHewan.size,
        hewan_terklaim: hewanTerklaim.size,
        hewan_tersedia: totalHewan.size - hewanTerklaim.size
      };
    } catch (error) {
      throw new functions.https.HttpsError('internal', 'Error mendapatkan statistik');
    }
  }
);

/**
 * Cloud Function untuk memberi makan hewan peliharaan
 */
export const beriMakan = functions.https.onCall(
  async (data: { uidTag: string }, context): Promise<KlaimHewanResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Pengguna harus login untuk memberi makan.'
      );
    }

    const userId = context.auth.uid;
    const { uidTag } = data;

    if (!uidTag || typeof uidTag !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'UID Tag NFC harus berupa string yang valid.'
      );
    }

    const db = admin.firestore();
    const hewanRef = db.collection('master_hewan').doc(uidTag);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const hewanDoc = await transaction.get(hewanRef);

        if (!hewanDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Hewan tidak ditemukan.'
          );
        }

        const hewanData = hewanDoc.data();

        if (hewanData?.id_pemilik !== userId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Anda bukan pemilik hewan ini.'
          );
        }

        // Cek Cooldown (3 menit)
        const sekarang = Date.now();
        const terakhirMakan = hewanData?.terakhir_diberi_makan
          ? (hewanData.terakhir_diberi_makan as admin.firestore.Timestamp).toDate().getTime()
          : 0;
        const selisihWaktu = sekarang - terakhirMakan;

        if (selisihWaktu < 3 * 60 * 1000) {
          const sisaDetik = Math.ceil((3 * 60 * 1000 - selisihWaktu) / 1000);
          throw new functions.https.HttpsError(
            'resource-exhausted',
            `Hewan masih kenyang. Tunggu ${sisaDetik} detik lagi.`
          );
        }

        // Hitung exp & level
        let level = hewanData?.level ?? 1;
        let exp = (hewanData?.exp ?? 0) + 20;
        let levelUp = false;

        if (exp >= 100) {
          level += 1;
          exp -= 100;
          levelUp = true;
        }

        const updateData: any = {
          'exp': exp,
          'level': level,
          'terakhir_diberi_makan': admin.firestore.FieldValue.serverTimestamp()
        };

        transaction.update(hewanRef, updateData);

        return {
          nama_hewan: hewanData?.nama_hewan || 'Hewan',
          level,
          exp,
          levelUp,
        };
      });

      return {
        status: 'sukses',
        data: result,
        message: result.levelUp 
          ? `Selamat! ${result.nama_hewan} naik ke Level ${result.level}!`
          : `${result.nama_hewan} kenyang dan senang! (+20 EXP)`
      };

    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error('Error dalam beriMakan:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Terjadi kesalahan internal.'
      );
    }
  }
);

/**
 * Cloud Function untuk melatih hewan peliharaan
 */
export const latihanHewan = functions.https.onCall(
  async (data: { uidTag: string }, context): Promise<KlaimHewanResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Pengguna harus login untuk melatih hewan.'
      );
    }

    const userId = context.auth.uid;
    const { uidTag } = data;

    if (!uidTag || typeof uidTag !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'UID Tag NFC harus berupa string yang valid.'
      );
    }

    const db = admin.firestore();
    const hewanRef = db.collection('master_hewan').doc(uidTag);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const hewanDoc = await transaction.get(hewanRef);

        if (!hewanDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Hewan tidak ditemukan.'
          );
        }

        const hewanData = hewanDoc.data();

        if (hewanData?.id_pemilik !== userId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Anda bukan pemilik hewan ini.'
          );
        }

        // Cek Cooldown (3 menit)
        const sekarang = Date.now();
        const terakhirLatihan = hewanData?.terakhir_latihan
          ? (hewanData.terakhir_latihan as admin.firestore.Timestamp).toDate().getTime()
          : 0;
        const selisihWaktu = sekarang - terakhirLatihan;

        if (selisihWaktu < 3 * 60 * 1000) {
          const sisaDetik = Math.ceil((3 * 60 * 1000 - selisihWaktu) / 1000);
          throw new functions.https.HttpsError(
            'resource-exhausted',
            `Hewan lelah setelah latihan. Tunggu ${sisaDetik} detik lagi.`
          );
        }

        // Hitung exp & level
        let level = hewanData?.level ?? 1;
        let exp = (hewanData?.exp ?? 0) + 30;
        let levelUp = false;

        if (exp >= 100) {
          level += 1;
          exp -= 100;
          levelUp = true;
        }

        const updateData: any = {
          'exp': exp,
          'level': level,
          'terakhir_latihan': admin.firestore.FieldValue.serverTimestamp()
        };

        transaction.update(hewanRef, updateData);

        return {
          nama_hewan: hewanData?.nama_hewan || 'Hewan',
          level,
          exp,
          levelUp,
        };
      });

      return {
        status: 'sukses',
        data: result,
        message: result.levelUp 
          ? `Selamat! ${result.nama_hewan} naik ke Level ${result.level}!`
          : `${result.nama_hewan} bertambah kuat setelah latihan! (+30 EXP)`
      };

    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error('Error dalam latihanHewan:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Terjadi kesalahan internal.'
      );
    }
  }
);
