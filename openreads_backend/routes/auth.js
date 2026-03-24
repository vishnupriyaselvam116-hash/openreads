const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken } = require('../utils/jwt');
const { protect } = require('../middleware/auth');

const sendError = (res, status, msg) =>
  res.status(status).json({ success: false, message: msg });

const sendSuccess = (res, data, msg = 'Success') =>
  res.json({ success: true, message: msg, data });

// ── REGISTER ──────────────────────────────────────────────────────────────────
router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name required'),
    body('email').isEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 6 }).withMessage('Min 6 characters'),
    body('role')
      .optional()
      .isIn(['user', 'author'])
      .withMessage('Role must be user or author'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ success: false, errors: errors.array() });

    try {
      const { name, email, password, role = 'user', penName } = req.body;

      const existing = await User.findOne({ email });
      if (existing) return sendError(res, 409, 'Email already registered.');

      const userData = { name, email, password, role };
      if (role === 'author' && penName) {
        userData.authorDetails = { penName };
      }

      const user = await User.create(userData);
      const token = generateToken(user._id, user.role);

      sendSuccess(
        res,
        {
          token,
          user: {
            id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
          },
        },
        'Registration successful'
      );
    } catch (err) {
      console.error(err);
      sendError(res, 500, 'Server error.');
    }
  }
);

// ── LOGIN ─────────────────────────────────────────────────────────────────────
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').notEmpty().withMessage('Password required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ success: false, errors: errors.array() });

    try {
      const { email, password, requiredRole } = req.body;

      const user = await User.findOne({ email }).select('+password');
      if (!user) return sendError(res, 401, 'Invalid email or password.');

      const isMatch = await user.comparePassword(password);
      if (!isMatch) return sendError(res, 401, 'Invalid email or password.');

      if (user.isBlocked)
        return sendError(res, 403, 'Account blocked. Contact support.');

      if (requiredRole && user.role !== requiredRole)
        return sendError(
          res,
          403,
          `This login is for ${requiredRole}s only.`
        );

      const token = generateToken(user._id, user.role);

      sendSuccess(
        res,
        {
          token,
          user: {
            id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            ...(user.role === 'author' && {
              authorDetails: user.authorDetails,
            }),
          },
        },
        'Login successful'
      );
    } catch (err) {
      console.error(err);
      sendError(res, 500, 'Server error.');
    }
  }
);

// ── GET ME ────────────────────────────────────────────────────────────────────
router.get('/me', protect, (req, res) => {
  const u = req.user;
  sendSuccess(res, {
    id: u._id,
    name: u.name,
    email: u.email,
    role: u.role,
    profileImage: u.profileImage,
    bio: u.bio,
    ...(u.role === 'author' && { authorDetails: u.authorDetails }),
  });
});

module.exports = router;