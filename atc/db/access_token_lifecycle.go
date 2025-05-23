package db

import (
	"fmt"
	"time"

	sq "github.com/Masterminds/squirrel"
)

//counterfeiter:generate . AccessTokenLifecycle
type AccessTokenLifecycle interface {
	RemoveExpiredAccessTokens(leeway time.Duration) (int, error)
}

type accessTokenLifecycle struct {
	conn DbConn
}

func NewAccessTokenLifecycle(conn DbConn) AccessTokenLifecycle {
	return &accessTokenLifecycle{conn}
}

func (a accessTokenLifecycle) RemoveExpiredAccessTokens(leeway time.Duration) (int, error) {
	res, err := sq.Delete("access_tokens").
		Where(
			sq.Expr(fmt.Sprintf("expires_at < now() - '%d seconds'::interval", int(leeway.Seconds()))),
		).
		RunWith(a.conn).
		Exec()
	if err != nil {
		return 0, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return 0, err
	}
	return int(n), nil
}
