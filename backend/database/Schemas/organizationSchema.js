const mongoose = require("mongoose");

const organizationSchema = new mongoose.Schema({
    id: {
        type: mongoose.Schema.Types.ObjectId,
        default: () => new mongoose.Types.ObjectId(),
        immutable: true
    }

    name: {
        type: String,
        required: true,
        trim: true
    }

    chapter: {
        type: String,
        required: true,
        trim: true
    }

    location: {
        type: String,
        required: true,
        trim: true
    }

    school: {
        type: String,
        required: true,
        trim: true
    }

    current_encrypted_key: {
        type: String,
        required: true,
        trim: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('organization', organizationSchema);