package mesh.crypto;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

public class CryptoUtils {

    public static KeyPair generateRsaKeyPair() throws Exception {
        KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
        gen.initialize(2048);
        return gen.generateKeyPair();
    }

    public static String publicKeyToBase64(PublicKey key) {
        return Base64.getEncoder().encodeToString(key.getEncoded());
    }

    public static String privateKeyToBase64(PrivateKey key) {
        return Base64.getEncoder().encodeToString(key.getEncoded());
    }

    public static PublicKey publicKeyFromBase64(String base64) throws Exception {
        return KeyFactory.getInstance("RSA")
                .generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(base64)));
    }

    public static PrivateKey privateKeyFromBase64(String base64) throws Exception {
        return KeyFactory.getInstance("RSA")
                .generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(base64)));
    }

    // A short readable ID for a device's public key — like an ID card number.
    public static String fingerprint(PublicKey key) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hash = digest.digest(key.getEncoded());
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 8; i++) {
            sb.append(String.format("%02X", hash[i]));
            if (i < 7) sb.append(":");
        }
        return sb.toString();
    }

    public static EncryptedPayload encrypt(String plaintext, PublicKey recipientPublicKey) throws Exception {
        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(256);
        SecretKey aesKey = keyGen.generateKey();

        byte[] iv = new byte[12];
        SecureRandom.getInstanceStrong().nextBytes(iv);

        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, new GCMParameterSpec(128, iv));
        byte[] ciphertext = aesCipher.doFinal(plaintext.getBytes("UTF-8"));

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        rsaCipher.init(Cipher.ENCRYPT_MODE, recipientPublicKey);
        byte[] wrappedKey = rsaCipher.doFinal(aesKey.getEncoded());

        EncryptedPayload payload = new EncryptedPayload();
        payload.iv = Base64.getEncoder().encodeToString(iv);
        payload.ciphertext = Base64.getEncoder().encodeToString(ciphertext);
        payload.wrappedKey = Base64.getEncoder().encodeToString(wrappedKey);
        return payload;
    }

    public static String decrypt(EncryptedPayload payload, PrivateKey myPrivateKey) throws Exception {
        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        rsaCipher.init(Cipher.DECRYPT_MODE, myPrivateKey);
        byte[] rawAesKey = rsaCipher.doFinal(Base64.getDecoder().decode(payload.wrappedKey));
        SecretKey aesKey = new SecretKeySpec(rawAesKey, "AES");

        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        aesCipher.init(Cipher.DECRYPT_MODE, aesKey,
                new GCMParameterSpec(128, Base64.getDecoder().decode(payload.iv)));
        byte[] plainBytes = aesCipher.doFinal(Base64.getDecoder().decode(payload.ciphertext));
        return new String(plainBytes, "UTF-8");
    }
}