const express = require('express');
const router = express.Router();
const Book = require('../models/Book');
const { protect, restrict } = require('../middleware/auth');

const sendError = (res, status, msg) =>
  res.status(status).json({ success: false, message: msg });

const sendSuccess = (res, data, msg = 'Success') =>
  res.json({ success: true, message: msg, data });

// ── GET ALL APPROVED BOOKS (public) ──────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const { category, search, sort = '-createdAt', limit = 20, page = 1 } = req.query;

    const filter = { status: 'approved' };
    if (category) filter.category = category;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { author: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const total = await Book.countDocuments(filter);
    const books = await Book.find(filter)
      .sort(sort)
      .limit(parseInt(limit))
      .skip(skip)
      .select('-ratings');

    sendSuccess(res, {
      books,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
    });
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── GET SINGLE BOOK ───────────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);
    if (!book) return sendError(res, 404, 'Book not found.');

    // Increment views
    book.views += 1;
    await book.save();

    sendSuccess(res, book);
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── GET BOOKS BY CATEGORY ─────────────────────────────────────────────────────
router.get('/category/:category', async (req, res) => {
  try {
    const books = await Book.find({
      status: 'approved',
      category: req.params.category,
    })
      .sort('-createdAt')
      .limit(20)
      .select('-ratings');

    sendSuccess(res, { books });
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── CREATE BOOK (author only) ─────────────────────────────────────────────────
router.post('/', protect, restrict('author', 'admin'), async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      coverImage,
      fileUrl,
      isPaid,
      price,
    } = req.body;

    if (!title || !description || !category) {
      return sendError(res, 400, 'Title, description and category required.');
    }

    const book = await Book.create({
      title,
      description,
      author: req.user.name,
      authorId: req.user._id,
      category,
      coverImage,
      fileUrl,
      isPaid: isPaid || false,
      price: isPaid ? price : 0,
      status: 'pending',
    });

    sendSuccess(res, book, 'Book submitted for approval.');
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── APPROVE BOOK (admin only) ─────────────────────────────────────────────────
router.patch('/:id/approve', protect, restrict('admin'), async (req, res) => {
  try {
    const book = await Book.findByIdAndUpdate(
      req.params.id,
      { status: 'approved' },
      { new: true }
    );
    if (!book) return sendError(res, 404, 'Book not found.');
    sendSuccess(res, book, 'Book approved.');
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── REJECT BOOK (admin only) ──────────────────────────────────────────────────
router.patch('/:id/reject', protect, restrict('admin'), async (req, res) => {
  try {
    const book = await Book.findByIdAndUpdate(
      req.params.id,
      { status: 'rejected' },
      { new: true }
    );
    if (!book) return sendError(res, 404, 'Book not found.');
    sendSuccess(res, book, 'Book rejected.');
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── DELETE BOOK (admin or author) ─────────────────────────────────────────────
router.delete('/:id', protect, async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);
    if (!book) return sendError(res, 404, 'Book not found.');

    if (
      req.user.role !== 'admin' &&
      book.authorId.toString() !== req.user._id.toString()
    ) {
      return sendError(res, 403, 'Not authorized.');
    }

    await book.deleteOne();
    sendSuccess(res, null, 'Book deleted.');
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── RATE BOOK (user only) ─────────────────────────────────────────────────────
router.post('/:id/rate', protect, async (req, res) => {
  try {
    const { rating } = req.body;
    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 400, 'Rating must be between 1 and 5.');
    }

    const book = await Book.findById(req.params.id);
    if (!book) return sendError(res, 404, 'Book not found.');

    const existing = book.ratings.find(
      (r) => r.userId.toString() === req.user._id.toString()
    );

    if (existing) {
      existing.rating = rating;
    } else {
      book.ratings.push({ userId: req.user._id, rating });
    }

    // Recalculate average
    const total = book.ratings.reduce((sum, r) => sum + r.rating, 0);
    book.averageRating = (total / book.ratings.length).toFixed(1);
    book.totalReviews = book.ratings.length;

    await book.save();
    sendSuccess(res, { averageRating: book.averageRating }, 'Rating saved.');
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

// ── GET AUTHOR'S BOOKS ────────────────────────────────────────────────────────
router.get('/my/books', protect, restrict('author'), async (req, res) => {
  try {
    const books = await Book.find({ authorId: req.user._id }).sort('-createdAt');
    sendSuccess(res, { books });
  } catch (err) {
    sendError(res, 500, 'Server error.');
  }
});

module.exports = router;