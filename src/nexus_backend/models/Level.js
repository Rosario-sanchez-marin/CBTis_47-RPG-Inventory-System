const mongoose = require('mongoose');

module.exports = mongoose.model('Level', new mongoose.Schema({
    level_number: { type: Number, required: true, unique: true },
    title: { type: String, required: true },
    difficulty: { type: String },
    reward_item_id: { type: String },
    lore_snippet: { type: String },
}));