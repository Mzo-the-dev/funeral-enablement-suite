require('dotenv/config');

const { Pool } = require('pg');

const [rawIdentity, ...reasonParts] = process.argv.slice(2);
const identity = rawIdentity?.trim().toLowerCase();
const reason = reasonParts.join(' ').trim();

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is required.');
  process.exitCode = 1;
} else if (!identity || !reason) {
  console.error('Usage: npm run admin:revoke -- <username-or-verified-email> <reason>');
  process.exitCode = 1;
} else if (reason.length > 500) {
  console.error('The revocation reason must be 500 characters or fewer.');
  process.exitCode = 1;
} else {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  async function revokePlatformAdmin() {
    const client = await pool.connect();
    let transactionStarted = false;

    try {
      await client.query('BEGIN');
      transactionStarted = true;

      const accounts = await client.query(
        `WITH candidates AS (
           SELECT user_id
             FROM funeral_spaces.auth_login_identifier
            WHERE normalized_value = $1
           UNION
           SELECT user_id
             FROM funeral_spaces.user_contact
            WHERE contact_type = 'email'
              AND is_verified = true
              AND normalized_value = $1
         )
         SELECT account.user_id, profile.given_name, profile.surname
           FROM candidates
           JOIN funeral_spaces.app_user account USING (user_id)
           JOIN funeral_spaces.user_profile profile USING (user_id)
          FOR UPDATE OF account`,
        [identity],
      );

      if (accounts.rowCount !== 1) {
        throw new Error('Exactly one account must match that username or verified email.');
      }

      const account = accounts.rows[0];
      const admin = await client.query(
        `SELECT is_active
           FROM funeral_spaces.platform_admin
          WHERE user_id = $1
          FOR UPDATE`,
        [account.user_id],
      );
      if (admin.rows[0]?.is_active !== true) {
        throw new Error('That account does not have an active platform-admin role.');
      }

      await client.query(
        `UPDATE funeral_spaces.platform_admin
            SET is_active = false, revoked_at = now(), revoked_by_user_id = NULL
          WHERE user_id = $1`,
        [account.user_id],
      );
      await client.query(
        `INSERT INTO funeral_spaces.platform_admin_audit
           (action, target_user_id, reason, before_data, after_data)
         VALUES ('platform_admin_revoked', $1, $2, $3::jsonb, $4::jsonb)`,
        [
          account.user_id,
          reason,
          JSON.stringify({ is_active: true }),
          JSON.stringify({ is_active: false }),
        ],
      );

      await client.query('COMMIT');
      transactionStarted = false;
      console.log(`Platform-admin role revoked for ${account.given_name} ${account.surname}.`);
    } catch (error) {
      if (transactionStarted) await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
      await pool.end();
    }
  }

  revokePlatformAdmin().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}