import mesh.crypto.CryptoUtils;
import mesh.crypto.EncryptedPayload;
import java.security.KeyPair;

public class CryptoTest {
    public static void main(String[] args) throws Exception {
        KeyPair alice = CryptoUtils.generateRsaKeyPair();
        String original = "secret message for the report";

        EncryptedPayload payload = CryptoUtils.encrypt(original, alice.getPublic());
        System.out.println("Ciphertext (what travels over the network):");
        System.out.println(payload.ciphertext);

        String decrypted = CryptoUtils.decrypt(payload, alice.getPrivate());
        System.out.println("\nDecrypted: " + decrypted);
        System.out.println("Match: " + original.equals(decrypted));
        System.out.println("Ciphertext contains plaintext? "
                + payload.ciphertext.contains(original));
    }
}